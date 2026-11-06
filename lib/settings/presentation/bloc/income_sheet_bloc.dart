import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_rule.dart';
import '../../../ledger/ledger.dart';
import 'income_sheet_event.dart';
import 'income_sheet_state.dart';

/// Owns the income sheet opened from Settings' *Money coming in* row (SPEC FR-SE-1, D137, D140):
/// the income, the amount question and *Change this month too* with its Undo, and the *When it
/// comes* question with its preview. Driven by `IncomeSheet`.
class IncomeSheetBloc extends Bloc<IncomeSheetEvent, IncomeSheetState> {
  IncomeSheetBloc({
    required Income income,
    required this._changeAmount,
    required this._correctPay,
    required this._changeRule,
    required this._summary,
    required this._newRuleLabel,
    required this._haptics,
  }) : super(IncomeSheetReady(income: income)) {
    on<IncomeSheetAmountOpened>(_onAmountOpened);
    on<IncomeSheetBackPressed>(_onBackPressed);
    on<IncomeSheetKeyPressed>(
      (IncomeSheetKeyPressed event, Emitter<IncomeSheetState> emit) =>
          _editAmount(emit, (int rupees, bool fresh) => AmountInput.append(fresh ? 0 : rupees, event.key)),
    );
    on<IncomeSheetBackspacePressed>(
      (IncomeSheetBackspacePressed event, Emitter<IncomeSheetState> emit) =>
          _editAmount(emit, (int rupees, bool _) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<IncomeSheetCleared>(
      (IncomeSheetCleared event, Emitter<IncomeSheetState> emit) => _editAmount(emit, (int _, bool _) => const Option<int>.of(0)),
    );
    // why: a second tap while a write is in flight must not write twice.
    on<IncomeSheetAmountSaved>(_onAmountSaved, transformer: droppable());
    on<IncomeSheetThisMonthChanged>(_onThisMonthChanged, transformer: droppable());
    on<IncomeSheetThisMonthUndone>(_onThisMonthUndone, transformer: droppable());
    on<IncomeSheetPayRuleSaved>(_onPayRuleSaved, transformer: droppable());
    on<IncomeSheetSavedNoteExpired>(_onSavedNoteExpired);
    on<IncomeSheetWhenOpened>(_onWhenOpened);
    on<IncomeSheetDayGridOpened>((IncomeSheetDayGridOpened event, Emitter<IncomeSheetState> emit) => _openStep(emit, IncomeWhenStep.day));
    on<IncomeSheetWeekdayGridOpened>(
      (IncomeSheetWeekdayGridOpened event, Emitter<IncomeSheetState> emit) => _openStep(emit, IncomeWhenStep.weekday),
    );
    // why: a newer pick's preview replaces an older one still loading, so a stale effect never lands last.
    on<IncomeSheetPayRuleChosen>(_onPayRuleChosen, transformer: restartable());
  }

  final ChangeIncomeAmount _changeAmount;
  final CorrectLatestPay _correctPay;
  final ChangePayRule _changeRule;
  final GetCycleSummary _summary;
  final Haptics _haptics;

  /// The name a salary rule gets when "It changes" moves to a fixed day ("Money in").
  final String _newRuleLabel;

  void _onAmountOpened(IncomeSheetAmountOpened event, Emitter<IncomeSheetState> emit) {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady || current.amountOpen || current.step.isSome()) {
      return;
    }
    current.income.rule.match(
      () {},
      (RecurringRule rule) => emit(current.copyWith(
        amountOpen: true,
        rupees: IncomeAmount.monthlyOf(rule).floorMajor,
        fresh: true,
        justSaved: false,
      )),
    );
  }

  void _onBackPressed(IncomeSheetBackPressed event, Emitter<IncomeSheetState> emit) {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady) {
      return;
    }
    emit(switch ((current.amountOpen, current.pendingRule.isSome(), current.step.toNullable())) {
      (true, true, _) => current.copyWith(
          amountOpen: false,
          pendingRule: const Option<PayRule>.none(),
          step: const Option<IncomeWhenStep>.of(IncomeWhenStep.choices),
        ),
      (true, false, _) => current.copyWith(amountOpen: false),
      (false, _, IncomeWhenStep.day || IncomeWhenStep.weekday) =>
        current.copyWith(step: const Option<IncomeWhenStep>.of(IncomeWhenStep.choices)),
      (false, _, IncomeWhenStep.choices) => current.copyWith(
          step: const Option<IncomeWhenStep>.none(),
          draft: const Option<PayRule>.none(),
          preview: const Option<CycleSummary>.none(),
        ),
      (false, _, null) => const IncomeSheetClosed(),
    });
  }

  Future<void> _onAmountSaved(IncomeSheetAmountSaved event, Emitter<IncomeSheetState> emit) async {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady || !current.amountOpen) {
      return;
    }
    if (current.rupees == 0) {
      unawaited(_haptics.reject());
      emit(current.copyWith(rejections: current.rejections + 1));
      return;
    }
    final Money monthly = Money.fromMajor(current.rupees);
    await current.pendingRule.match(
      () => _saveAmount(emit, current, monthly),
      (PayRule rule) => _saveRule(emit, current, rule, Option<Money>.of(monthly)),
    );
  }

  Future<void> _saveAmount(Emitter<IncomeSheetState> emit, IncomeSheetReady form, Money monthly) async {
    // why: the amount question opens without a pending rule only when there is a salary rule.
    final RecurringRule? before = form.income.rule.toNullable();
    if (before == null) {
      return;
    }
    emit(form.copyWith(saving: true));
    final Either<Failure, RecurringRule> saved = await _changeAmount(ChangeIncomeAmountParams(rule: before, monthly: monthly)).run();
    saved.match(
      (Failure failure) => _failed(emit, form, failure),
      (RecurringRule after) => emit(_afterAmountSave(form, before, after)),
    );
  }

  IncomeSheetReady _afterAmountSave(IncomeSheetReady form, RecurringRule before, RecurringRule after) {
    if (after == before) {
      return form.copyWith(amountOpen: false);
    }
    unawaited(_haptics.tick());
    return form.copyWith(
      income: Income(rule: Option<RecurringRule>.of(after), latestPay: form.income.latestPay),
      amountOpen: false,
      justSaved: true,
      changed: true,
      fixable: _fixable(form, before, after),
      lastsTill: const Option<CalendarDate>.none(),
    );
  }

  // why: only a pay the rule posted at its old amount is offered, so a pay the person already
  // changed by hand is never overwritten (D137).
  static Option<Entry> _fixable(IncomeSheetReady form, RecurringRule before, RecurringRule after) => form.income.latestPay.filter(
        (Entry pay) => (form.fixable.isSome() || pay.amount == before.amount) && pay.amount != after.amount,
      );

  void _onWhenOpened(IncomeSheetWhenOpened event, Emitter<IncomeSheetState> emit) {
    final IncomeSheetState current = state;
    if (current is IncomeSheetReady && !current.amountOpen && current.step.isNone()) {
      emit(current.copyWith(
        step: const Option<IncomeWhenStep>.of(IncomeWhenStep.choices),
        draft: Option<PayRule>.of(current.payRule),
        preview: const Option<CycleSummary>.none(),
        justSaved: false,
      ));
    }
  }

  void _openStep(Emitter<IncomeSheetState> emit, IncomeWhenStep step) {
    final IncomeSheetState current = state;
    if (current is IncomeSheetReady && current.step == const Option<IncomeWhenStep>.of(IncomeWhenStep.choices)) {
      emit(current.copyWith(step: Option<IncomeWhenStep>.of(step)));
    }
  }

  Future<void> _onPayRuleChosen(IncomeSheetPayRuleChosen event, Emitter<IncomeSheetState> emit) async {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady || current.step.isNone()) {
      return;
    }
    final IncomeSheetReady picked = current.copyWith(
      step: const Option<IncomeWhenStep>.of(IncomeWhenStep.choices),
      draft: Option<PayRule>.of(event.rule),
      preview: const Option<CycleSummary>.none(),
    );
    unawaited(_haptics.tick());
    emit(picked);
    if (!picked.draftChanged) {
      return;
    }
    final Either<Failure, CycleSummary> preview = await _summary.preview(event.rule).run();
    final IncomeSheetState latest = state;
    if (latest is IncomeSheetReady && latest.draft == picked.draft) {
      emit(latest.copyWith(preview: preview.toOption()));
    }
  }

  Future<void> _onPayRuleSaved(IncomeSheetPayRuleSaved event, Emitter<IncomeSheetState> emit) async {
    final IncomeSheetState current = state;
    final PayRule? rule = current is IncomeSheetReady && current.draftChanged ? current.draft.toNullable() : null;
    if (current is! IncomeSheetReady || rule == null) {
      return;
    }
    // why: a salary rule can't exist without an amount, so "It changes" to a fixed day asks it first.
    if (current.income.rule.isNone() && rule is! IrregularIncome) {
      emit(current.copyWith(
        amountOpen: true,
        pendingRule: Option<PayRule>.of(rule),
        rupees: current.income.receivedThisMonth.floorMajor,
        fresh: true,
        step: const Option<IncomeWhenStep>.none(),
      ));
      return;
    }
    await _saveRule(emit, current, rule, const Option<Money>.none());
  }

  Future<void> _saveRule(Emitter<IncomeSheetState> emit, IncomeSheetReady form, PayRule rule, Option<Money> monthly) async {
    emit(form.copyWith(saving: true));
    final Either<Failure, Option<RecurringRule>> saved = await _changeRule(
      ChangePayRuleParams(income: form.income.rule, to: rule, monthly: monthly, label: _newRuleLabel),
    ).run();
    saved.match((Failure failure) => _failed(emit, form, failure), (Option<RecurringRule> after) {
      unawaited(_haptics.tick());
      emit(IncomeSheetReady(
        income: Income(rule: after, latestPay: form.income.latestPay),
        justSaved: true,
        changed: true,
        lastsTill: form.preview.map((CycleSummary summary) => summary.cycle.end),
      ));
    });
  }

  Future<void> _onThisMonthChanged(IncomeSheetThisMonthChanged event, Emitter<IncomeSheetState> emit) async {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady) {
      return;
    }
    final Option<(Entry, Money)> target = current.fixable.flatMap(
      (Entry pay) => current.income.rule.map((RecurringRule rule) => (pay, rule.amount)),
    );
    if (target case Some(value: (final Entry pay, final Money amount))) {
      final Either<Failure, Entry> saved = await _correctPay(CorrectLatestPayParams(pay: pay, amount: amount)).run();
      saved.match((Failure failure) => _failed(emit, current, failure), (Entry after) {
        unawaited(_haptics.success());
        emit(current.copyWith(
          income: Income(rule: current.income.rule, latestPay: Option<Entry>.of(after)),
          fixable: const Option<Entry>.none(),
          corrected: Option<Entry>.of(pay),
        ));
      });
    }
  }

  Future<void> _onThisMonthUndone(IncomeSheetThisMonthUndone event, Emitter<IncomeSheetState> emit) async {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady) {
      return;
    }
    final Option<(Entry, Entry)> target =
        current.corrected.flatMap((Entry before) => current.income.latestPay.map((Entry now) => (now, before)));
    if (target case Some(value: (final Entry now, final Entry before))) {
      final Either<Failure, Entry> saved = await _correctPay(CorrectLatestPayParams(pay: now, amount: before.amount)).run();
      saved.match((Failure failure) => _failed(emit, current, failure), (Entry restored) {
        unawaited(_haptics.tick());
        emit(current.copyWith(
          income: Income(rule: current.income.rule, latestPay: Option<Entry>.of(restored)),
          fixable: Option<Entry>.of(restored),
          corrected: const Option<Entry>.none(),
        ));
      });
    }
  }

  void _onSavedNoteExpired(IncomeSheetSavedNoteExpired event, Emitter<IncomeSheetState> emit) {
    final IncomeSheetState current = state;
    if (current is IncomeSheetReady) {
      emit(current.copyWith(justSaved: false));
    }
  }

  void _failed(Emitter<IncomeSheetState> emit, IncomeSheetReady form, Failure failure) {
    AppLogger.log(tag: 'income.sheet_save_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
    unawaited(_haptics.reject());
    emit(form.copyWith(saveFailed: true));
  }

  void _editAmount(Emitter<IncomeSheetState> emit, Option<int> Function(int rupees, bool fresh) edit) {
    final IncomeSheetState current = state;
    if (current is! IncomeSheetReady || !current.amountOpen) {
      return;
    }
    edit(current.rupees, current.fresh).match(
      () {
        unawaited(_haptics.reject());
        emit(current.copyWith(rejections: current.rejections + 1));
      },
      (int rupees) {
        unawaited(_haptics.tick());
        emit(current.copyWith(rupees: rupees, fresh: false));
      },
    );
  }
}
