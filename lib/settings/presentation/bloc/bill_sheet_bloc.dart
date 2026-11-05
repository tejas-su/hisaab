import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import 'bill_sheet_event.dart';
import 'bill_sheet_state.dart';

/// Owns one fixed bill shown in the bill sheet (SPEC FR-SE-1, D118): the bill, the question
/// open on it, and saving one answer at a time. Driven by `BillSheet`.
///
/// It never deletes: *Delete bill* closes with [BillSheetDeleted] so the opening screen can
/// delete and offer Undo.
class BillSheetBloc extends Bloc<BillSheetEvent, BillSheetState> {
  BillSheetBloc({
    required RecurringRule rule,
    required this._editBill,
    required this._getStatus,
    required this._haptics,
  }) : super(BillSheetReady(rule: rule)) {
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
    add(const BillSheetStatusRequested());
  }

  final EditBill _editBill;
  final GetBillStatus _getStatus;
  final Haptics _haptics;

  Future<void> _onStatusRequested(BillSheetStatusRequested event, Emitter<BillSheetState> emit) => _loadStatus(emit);

  Future<void> _loadStatus(Emitter<BillSheetState> emit) async {
    final BillSheetState current = state;
    if (current is! BillSheetReady) {
      return;
    }
    final Either<Failure, BillStatus> status = await _getStatus(current.rule).run();
    final BillSheetState latest = state;
    if (latest is BillSheetReady) {
      emit(latest.copyWith(status: status.toOption(), saving: latest.saving));
    }
  }

  void _onAnswerOpened(BillSheetAnswerOpened event, Emitter<BillSheetState> emit) => _whenOnBill((BillSheetReady bill) => emit(
        bill.copyWith(
          open: Option<BillAnswer>.of(event.answer),
          rupees: bill.rule.amount.floorMajor,
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

  void _onSavedNoteExpired(BillSheetSavedNoteExpired event, Emitter<BillSheetState> emit) {
    final BillSheetState current = state;
    if (current is BillSheetReady) {
      emit(current.copyWith(justSaved: const Option<BillAnswer>.none()));
    }
  }

  /// Saves [input] for the open question, or just returns to the bill when it is none
  /// (the answer didn't change).
  Future<void> _save(Emitter<BillSheetState> emit, BillSheetReady form, Option<BillInput> input) async {
    final BillAnswer answer = form.open.getOrElse(() => BillAnswer.amount);
    if (input case None()) {
      emit(form.copyWith(open: const Option<BillAnswer>.none()));
      return;
    }
    emit(form.copyWith(saving: true));
    final Either<Failure, RecurringRule> saved =
        await _editBill(EditBillParams(rule: form.rule, input: input.getOrElse(() => _inputOf(form.rule)))).run();
    await saved.match(
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
          justSaved: Option<BillAnswer>.of(answer),
          changed: true,
        ));
        return _loadStatus(emit);
      },
    );
  }

  void _editAmount(Emitter<BillSheetState> emit, Option<int> Function(int rupees, bool fresh) edit) {
    final BillSheetState current = state;
    if (current is! BillSheetReady || current.open != const Option<BillAnswer>.of(BillAnswer.amount)) {
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
