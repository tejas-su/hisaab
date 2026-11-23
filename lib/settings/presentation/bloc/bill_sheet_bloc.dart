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
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'bill_sheet_event.dart';
import 'bill_sheet_state.dart';

/// Owns one fixed bill shown in the bill sheet (SPEC FR-SE-1, D118): the bill, the question
/// open on it, and saving one answer at a time. Driven by `BillSheet`.
///
/// It never deletes a bill: *Delete bill* closes with [BillSheetDeleted] so the opening screen can
/// delete and offer Undo. A reached saving's *I bought it* is the one exception: it writes *Used*
/// and deletes in one step, then closes with [BillSheetBought] for the opening screen's Undo (D213).
class BillSheetBloc extends Bloc<BillSheetEvent, BillSheetState> {
  BillSheetBloc({
    required RecurringRule rule,
    required this._editBill,
    required this._getStatus,
    required this._haptics,
    this._getSetAside,
    this._useFromSavings,
    this._deleteBill,
    this._deleteEntry,
    Clock? clock,
  }) : super(BillSheetReady(rule: rule, today: Option<CalendarDate>.fromNullable(clock?.today()))) {
    on<BillSheetStatusRequested>(_onStatusRequested, transformer: restartable());
    on<BillSheetAnswerOpened>(_onAnswerOpened);
    on<BillSheetBackPressed>(_onBackPressed);
    on<BillSheetKeyPressed>(
      (BillSheetKeyPressed event, Emitter<BillSheetState> emit) =>
          _editAmount(emit, (int rupees, bool fresh) => AmountInput.append(fresh ? 0 : rupees, event.key)),
    );
    on<BillSheetBackspacePressed>(
      (BillSheetBackspacePressed event, Emitter<BillSheetState> emit) =>
          _editAmount(emit, (int rupees, bool _) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<BillSheetCleared>(
      (BillSheetCleared event, Emitter<BillSheetState> emit) => _editAmount(emit, (int _, bool _) => const Option<int>.of(0)),
    );
    // why: a second tap while a save is in flight must not save twice.
    on<BillSheetAmountSaved>(_onAmountSaved, transformer: droppable());
    on<BillSheetDayChosen>(_onDayChosen, transformer: droppable());
    on<BillSheetModeChosen>(_onModeChosen, transformer: droppable());
    on<BillSheetNameChanged>(_onNameChanged);
    on<BillSheetNameSaved>(_onNameSaved, transformer: droppable());
    on<BillSheetIconChosen>(_onIconChosen, transformer: droppable());
    on<BillSheetDeleteRequested>(_onDeleteRequested);
    on<BillSheetSavedNoteExpired>(_onSavedNoteExpired);
    on<BillSheetTargetSaved>(_onTargetSaved, transformer: droppable());
    on<BillSheetTargetCleared>(_onTargetCleared, transformer: droppable());
    on<BillSheetBoughtRequested>(_onBoughtRequested, transformer: droppable());
    on<BillSheetKeepSavingRequested>(_onKeepSavingRequested, transformer: droppable());
    add(const BillSheetStatusRequested());
  }

  final EditBill _editBill;
  final GetBillStatus _getStatus;
  final Haptics _haptics;

  /// Reads what a saving has set aside; null for a bill sheet that never offers *Used some of it*.
  final GetSetAside? _getSetAside;

  /// Writes *I bought it*'s *Used* entry; null for a bill sheet, which never offers it.
  final UseFromSavings? _useFromSavings;

  /// Deletes the saving after *I bought it*; null for a bill sheet, which never offers it.
  final DeleteBill? _deleteBill;

  /// Takes *I bought it*'s *Used* entry back when the saving can't be deleted; null for a bill sheet.
  final DeleteEntry? _deleteEntry;

  Future<void> _onStatusRequested(BillSheetStatusRequested event, Emitter<BillSheetState> emit) => _loadStatus(emit);

  Future<void> _loadStatus(Emitter<BillSheetState> emit) async {
    final BillSheetState current = state;
    if (current is! BillSheetReady) {
      return;
    }
    final Either<Failure, BillStatus> status = await _getStatus(current.rule).run();
    final Option<Money> setAside = await _readSetAside(current.rule);
    final BillSheetState latest = state;
    if (latest is BillSheetReady) {
      emit(latest.copyWith(status: status.toOption(), saving: latest.saving, setAside: setAside));
    }
  }

  // why: a failed read just leaves the key off; the sheet stays usable without it.
  Future<Option<Money>> _readSetAside(RecurringRule rule) async {
    final GetSetAside? read = _getSetAside;
    if (read == null || rule.kind != EntryKind.saved) {
      return const Option<Money>.none();
    }
    final Either<Failure, SetAsideSummary> summary = await read(const NoParams()).run();
    return summary.toOption().flatMap((SetAsideSummary s) => Option<Money>.fromNullable(s.perSaving[rule.id]));
  }

  void _onAnswerOpened(BillSheetAnswerOpened event, Emitter<BillSheetState> emit) => _whenOnBill((BillSheetReady bill) => emit(
        bill.copyWith(
          open: Option<BillAnswer>.of(event.answer),
          rupees: event.answer == BillAnswer.target
              ? bill.rule.target.map((Money target) => target.floorMajor).getOrElse(() => 0)
              : bill.rule.amount.floorMajor,
          fresh: true,
          draftName: bill.rule.label,
          justSaved: const Option<BillAnswer>.none(),
        ),
      ));

  void _onBackPressed(BillSheetBackPressed event, Emitter<BillSheetState> emit) {
    final BillSheetState current = state;
    if (current is! BillSheetReady) {
      return;
    }
    emit(current.open.isSome() ? current.copyWith(open: const Option<BillAnswer>.none()) : BillSheetClosed(current.outcome));
  }

  Future<void> _onAmountSaved(BillSheetAmountSaved event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.amount,
        (BillSheetReady form) {
          if (form.rupees == 0) {
            unawaited(_haptics.reject());
            emit(form.copyWith(rejections: form.rejections + 1));
            return Future<void>.value();
          }
          final Money amount = Money.fromMajor(form.rupees);
          return _save(emit, form, amount == form.rule.amount ? none() : Option<BillInput>.of(_inputOf(form.rule, amount: amount)));
        },
      );

  Future<void> _onDayChosen(BillSheetDayChosen event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.day,
        (BillSheetReady form) => _save(
          emit,
          form,
          event.day == form.rule.schedule.anchor.day ? none() : Option<BillInput>.of(_inputOf(form.rule, dueDay: event.day)),
        ),
      );

  Future<void> _onModeChosen(BillSheetModeChosen event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.mode,
        (BillSheetReady form) => _save(
          emit,
          form,
          event.mode == form.rule.amountMode ? none() : Option<BillInput>.of(_inputOf(form.rule, amountMode: event.mode)),
        ),
      );

  void _onNameChanged(BillSheetNameChanged event, Emitter<BillSheetState> emit) {
    final BillSheetState current = state;
    if (current is BillSheetReady && current.open == const Option<BillAnswer>.of(BillAnswer.name)) {
      emit(current.copyWith(draftName: event.name));
    }
  }

  Future<void> _onNameSaved(BillSheetNameSaved event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.name,
        (BillSheetReady form) {
          final String name = form.draftName.trim();
          if (name.isEmpty) {
            return Future<void>.value();
          }
          return _save(emit, form, name == form.rule.label ? none() : Option<BillInput>.of(_inputOf(form.rule, label: name)));
        },
      );

  // why: picking the icon the name already suggests stores none, so a later rename moves the
  // icon with the name (SPEC BR-9).
  Future<void> _onIconChosen(BillSheetIconChosen event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.icon,
        (BillSheetReady form) {
          final Option<BillIcon> icon =
              event.icon == BillIcon.forName(form.rule.label) ? const Option<BillIcon>.none() : Option<BillIcon>.of(event.icon);
          return _save(emit, form, icon == form.rule.icon ? none() : Option<BillInput>.of(_inputOf(form.rule, icon: icon)));
        },
      );

  void _onDeleteRequested(BillSheetDeleteRequested event, Emitter<BillSheetState> emit) =>
      _whenOnBill((BillSheetReady bill) => emit(BillSheetClosed(BillSheetDeleted(bill.rule))));

  // why: Save is off at ₹0 (F4). A target already covered by what is set aside is stored as
  // announced (target_reached_for only), so Home never says "reached" for it (F1, E147).
  Future<void> _onTargetSaved(BillSheetTargetSaved event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.target,
        (BillSheetReady form) {
          if (form.rupees == 0) {
            return Future<void>.value();
          }
          final Money target = Money.fromMajor(form.rupees);
          if (form.rule.target == Option<Money>.of(target)) {
            return _save(emit, form, none());
          }
          final RecurringRule rule = form.rule.copyWith(target: Option<Money>.of(target));
          final bool covered = form.setAside.getOrElse(() => Money.zero).compareTo(target) >= 0;
          return _saveRule(
            emit,
            form,
            covered ? rule.copyWith(targetReachedFor: Option<Money>.of(target), targetReachedOn: const Option<CalendarDate>.none()) : rule,
          );
        },
      );

  Future<void> _onTargetCleared(BillSheetTargetCleared event, Emitter<BillSheetState> emit) => _whenAt(
        BillAnswer.target,
        (BillSheetReady form) => form.rule.target.isNone() ? Future<void>.value() : _saveRule(emit, form, _withoutTarget(form.rule)),
      );

  Future<void> _onKeepSavingRequested(BillSheetKeepSavingRequested event, Emitter<BillSheetState> emit) {
    final BillSheetState current = state;
    if (current is! BillSheetReady || current.open.isSome()) {
      return Future<void>.value();
    }
    return _saveRule(emit, current, _withoutTarget(current.rule));
  }

  // why: the Used write comes first; if the saving then can't be deleted, the entry is taken back
  // so nothing half-done is left and the sheet stays with "Couldn't save." (AC-T9).
  Future<void> _onBoughtRequested(BillSheetBoughtRequested event, Emitter<BillSheetState> emit) async {
    final BillSheetState current = state;
    final UseFromSavings? use = _useFromSavings;
    if (current is! BillSheetReady || current.open.isSome() || use == null || _deleteBill == null || _deleteEntry == null) {
      return;
    }
    final Money whole = Money.fromMajor(current.setAside.getOrElse(() => Money.zero).floorMajor);
    emit(current.copyWith(saving: true));
    final Either<Failure, Entry> used = await use(UseFromSavingsParams(saving: current.rule, amount: whole)).run();
    await used.match(
      (Failure failure) async => _failBought(emit, current, failure),
      (Entry entry) => _deleteBought(emit, current, UsedOutcome(entry: entry, saving: current.rule)),
    );
  }

  void _failBought(Emitter<BillSheetState> emit, BillSheetReady form, Failure failure) {
    AppLogger.log(tag: 'bills.sheet_bought_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
    unawaited(_haptics.reject());
    emit(form.copyWith(saveFailed: true));
  }

  Future<void> _deleteBought(Emitter<BillSheetState> emit, BillSheetReady form, UsedOutcome outcome) async {
    // why: both are non-null here; _onBoughtRequested returns early without them.
    final Either<Failure, Unit> deleted = await _deleteBill!(outcome.saving.id).run();
    await deleted.match(
      (Failure failure) async {
        AppLogger.log(tag: 'bills.sheet_bought_delete_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        await _rollBackBought(emit, form, outcome);
      },
      (Unit _) async {
        unawaited(_haptics.tick());
        emit(BillSheetClosed(BillSheetBought(outcome)));
      },
    );
  }

  // why: if the Used entry can't be taken back either, closing as a plain Used save is the only
  // honest outcome left: the opening screen offers that entry's own Undo.
  Future<void> _rollBackBought(Emitter<BillSheetState> emit, BillSheetReady form, UsedOutcome outcome) async {
    // why: non-null here; _onBoughtRequested returns early without it.
    final Either<Failure, Entry> undone = await _deleteEntry!(outcome.entry.id).run();
    unawaited(_haptics.reject());
    undone.match(
      (Failure failure) {
        AppLogger.log(tag: 'bills.sheet_bought_rollback_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        emit(BillSheetClosed(BillSheetUsed(outcome)));
      },
      (Entry _) => emit(form.copyWith(saveFailed: true)),
    );
  }

  static RecurringRule _withoutTarget(RecurringRule rule) => rule.copyWith(
        target: const Option<Money>.none(),
        targetReachedFor: const Option<Money>.none(),
        targetReachedOn: const Option<CalendarDate>.none(),
      );

  void _onSavedNoteExpired(BillSheetSavedNoteExpired event, Emitter<BillSheetState> emit) {
    final BillSheetState current = state;
    if (current is BillSheetReady) {
      emit(current.copyWith(justSaved: const Option<BillAnswer>.none()));
    }
  }

  /// Saves [input] for the open question, or just returns to the bill when it is none
  /// (the answer didn't change).
  Future<void> _save(Emitter<BillSheetState> emit, BillSheetReady form, Option<BillInput> input) async {
    if (input case Some<BillInput>(:final BillInput value)) {
      return _write(emit, form, EditBillParams(rule: form.rule, input: value));
    }
    emit(form.copyWith(open: const Option<BillAnswer>.none()));
  }

  /// Saves [rule]'s target columns, which a [BillInput] does not carry, as the *Saving up to* answer.
  // why: EditBill keeps every field of the rule it is given that the input doesn't name.
  Future<void> _saveRule(Emitter<BillSheetState> emit, BillSheetReady form, RecurringRule rule) =>
      _write(emit, form, EditBillParams(rule: rule, input: _inputOf(form.rule)), answer: BillAnswer.target);

  Future<void> _write(Emitter<BillSheetState> emit, BillSheetReady form, EditBillParams params, {BillAnswer? answer}) async {
    final BillAnswer saved = answer ?? form.open.getOrElse(() => BillAnswer.amount);
    emit(form.copyWith(saving: true));
    final Either<Failure, RecurringRule> written = await _editBill(params).run();
    await written.match(
      (Failure failure) async {
        AppLogger.log(tag: 'bills.sheet_save_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        unawaited(_haptics.reject());
        emit(form.copyWith(saveFailed: true));
      },
      (RecurringRule rule) {
        unawaited(_haptics.tick());
        emit(form.copyWith(
          rule: rule,
          open: const Option<BillAnswer>.none(),
          justSaved: Option<BillAnswer>.of(saved),
          changed: true,
        ));
        return _loadStatus(emit);
      },
    );
  }

  void _editAmount(Emitter<BillSheetState> emit, Option<int> Function(int rupees, bool fresh) edit) {
    final BillSheetState current = state;
    final BillAnswer? open = current is BillSheetReady ? current.open.toNullable() : null;
    if (current is! BillSheetReady || (open != BillAnswer.amount && open != BillAnswer.target)) {
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

  Future<void> _whenAt(BillAnswer answer, Future<void> Function(BillSheetReady form) action) {
    final BillSheetState current = state;
    if (current is BillSheetReady && current.open == Option<BillAnswer>.of(answer)) {
      return action(current);
    }
    return Future<void>.value();
  }

  void _whenOnBill(void Function(BillSheetReady bill) action) {
    final BillSheetState current = state;
    if (current is BillSheetReady && current.open.isNone()) {
      action(current);
    }
  }

  // why: every answer saves the whole input, so each one carries the rule's mode; a default
  // here would quietly turn a changing bill back into a fixed one (D123).
  static BillInput _inputOf(
    RecurringRule rule, {
    String? label,
    Money? amount,
    int? dueDay,
    Option<BillIcon>? icon,
    AmountMode? amountMode,
  }) =>
      BillInput(
        label: label ?? rule.label,
        amount: amount ?? rule.amount,
        dueDay: dueDay ?? rule.schedule.anchor.day,
        icon: icon ?? rule.icon,
        amountMode: amountMode ?? rule.amountMode,
      );
}
