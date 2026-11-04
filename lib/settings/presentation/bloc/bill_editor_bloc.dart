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
import 'bill_editor_event.dart';
import 'bill_editor_state.dart';

/// Owns one fixed bill, or one saving when [kind] is *Saved*, being added in Settings (SPEC
/// FR-SE-1, D120): its name, then its amount on the keypad, then its day, which saves. Driven
/// by the bill editor page. Changing one happens in the bill sheet instead (D118).
class BillEditorBloc extends Bloc<BillEditorEvent, BillEditorState> {
  BillEditorBloc({
    required this._addBill,
    required this._haptics,
    this.kind = EntryKind.spent,
  }) : super(const BillEditorInProgress()) {
    on<BillEditorRenamed>(_onRenamed);
    on<BillEditorKindPicked>(_onKindPicked);
    on<BillEditorSavingPicked>(_onSavingPicked);
    on<BillEditorNextPressed>(_onNextPressed);
    on<BillEditorKeyPressed>(
      (BillEditorKeyPressed event, Emitter<BillEditorState> emit) =>
          _editAmount(emit, (int rupees) => AmountInput.append(rupees, event.key)),
    );
    on<BillEditorBackspacePressed>(
      (BillEditorBackspacePressed event, Emitter<BillEditorState> emit) =>
          _editAmount(emit, (int rupees) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<BillEditorCleared>(
      (BillEditorCleared event, Emitter<BillEditorState> emit) => _editAmount(emit, (int _) => const Option<int>.of(0)),
    );
    // why: a second day tap while the first save is in flight must not save the bill twice.
    on<BillEditorDayChosen>(_onDayChosen, transformer: droppable());
    on<BillEditorBackPressed>(_onBackPressed);
  }

  final AddBill _addBill;
  final Haptics _haptics;

  /// What is being added: a bill (*Spent*) or a saving (*Saved*).
  final EntryKind kind;

  void _onRenamed(BillEditorRenamed event, Emitter<BillEditorState> emit) => _whenAt(
        BillEditorStage.name,
        (BillEditorInProgress form) => emit(form.copyWith(label: event.label, kind: const Option<BillKind>.none())),
      );

  // why: a pick only fills the name, so nothing changes under the person while they're naming the bill;
  // Next moves on, as with a typed name (D86).
  void _onKindPicked(BillEditorKindPicked event, Emitter<BillEditorState> emit) => _whenAt(
        BillEditorStage.name,
        (BillEditorInProgress form) {
          unawaited(_haptics.tick());
          emit(form.copyWith(label: event.label, kind: Option<BillKind>.of(event.kind)));
        },
      );

  void _onSavingPicked(BillEditorSavingPicked event, Emitter<BillEditorState> emit) => _whenAt(
        BillEditorStage.name,
        (BillEditorInProgress form) {
          unawaited(_haptics.tick());
          emit(form.copyWith(label: event.label, kind: const Option<BillKind>.none()));
        },
      );

  /// Moves from the name to the amount (needs a name), or from the amount to the day (needs
  /// more than ₹0).
  void _onNextPressed(BillEditorNextPressed event, Emitter<BillEditorState> emit) {
    final BillEditorState current = state;
    if (current is! BillEditorInProgress) {
      return;
    }
    if (current.stage == BillEditorStage.name && current.label.trim().isNotEmpty) {
      emit(current.copyWith(stage: BillEditorStage.amount));
    }
    if (current.stage == BillEditorStage.amount && current.rupees > 0) {
      emit(current.copyWith(stage: BillEditorStage.day));
    }
  }

  Future<void> _onDayChosen(BillEditorDayChosen event, Emitter<BillEditorState> emit) async {
    final BillEditorState current = state;
    if (current is! BillEditorInProgress || current.stage != BillEditorStage.day) {
      return;
    }
    emit(current.copyWith(saving: true));
    final BillInput input = BillInput(label: current.label, amount: Money.fromMajor(current.rupees), dueDay: event.day);
    final Either<Failure, RecurringRule> saved = await _addBill(AddBillParams(input: input, kind: current.kind, entryKind: kind)).run();
    saved.match(
      (Failure failure) {
        AppLogger.log(tag: 'bills.save_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        unawaited(_haptics.reject());
        emit(current.copyWith(saveFailed: true));
      },
      (RecurringRule _) {
        unawaited(_haptics.success());
        emit(const BillEditorSaved());
      },
    );
  }

  /// Steps back one question: day → amount → name. On the name the page closes instead.
  void _onBackPressed(BillEditorBackPressed event, Emitter<BillEditorState> emit) {
    final BillEditorState current = state;
    if (current is! BillEditorInProgress || current.stage == BillEditorStage.name) {
      return;
    }
    emit(current.copyWith(stage: BillEditorStage.values[current.stage.index - 1]));
  }

  void _editAmount(Emitter<BillEditorState> emit, Option<int> Function(int rupees) edit) => _whenAt(
        BillEditorStage.amount,
        (BillEditorInProgress form) => edit(form.rupees).match(
          () {
            unawaited(_haptics.reject());
            emit(form.copyWith(rejections: form.rejections + 1));
          },
          (int rupees) {
            unawaited(_haptics.tick());
            emit(form.copyWith(rupees: rupees));
          },
        ),
      );

  void _whenAt(BillEditorStage stage, void Function(BillEditorInProgress form) action) {
    final BillEditorState current = state;
    if (current is BillEditorInProgress && current.stage == stage) {
      action(current);
    }
  }
}
