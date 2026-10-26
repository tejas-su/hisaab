import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import 'bill_editor_state.dart';

/// Owns one fixed bill being added or changed in Settings (SPEC FR-SE-1): its name, then its
/// amount on the keypad, then its due day, which saves. Driven by the bill editor page.
///
/// [editing] is the bill being changed, or none to add a new one.
class BillEditorCubit extends Cubit<BillEditorState> {
  BillEditorCubit({
    required this._addBill,
    required this._editBill,
    required this._haptics,
    required this._editing,
  }) : super(
          _editing.match(
            () => const BillEditorInProgress(),
            (RecurringRule rule) =>
                BillEditorInProgress(label: rule.label, rupees: rule.amount.floorMajor, isEditing: true),
          ),
        );

  final AddBill _addBill;
  final EditBill _editBill;
  final Haptics _haptics;
  final Option<RecurringRule> _editing;

  /// The user typed [label] as the name; it no longer matches a chip.
  void rename(String label) =>
      _whenAt(BillEditorStage.name, (BillEditorInProgress form) => emit(form.copyWith(label: label, kind: const Option<BillKind>.none())));

  /// Picks the common bill [kind], named [label], and moves to the amount.
  void pickKind(BillKind kind, String label) => _whenAt(
        BillEditorStage.name,
        (BillEditorInProgress form) =>
            emit(form.copyWith(label: label, kind: Option<BillKind>.of(kind), stage: BillEditorStage.amount)),
      );

  /// Moves from the name to the amount (needs a name), or from the amount to the day (needs
  /// more than ₹0).
  void next() {
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

  /// Types [key] (`0`–`9`, `00`) into the amount.
  Future<void> pressKey(String key) async => _editAmount((int rupees) => AmountInput.append(rupees, key));

  /// Removes the last digit.
  Future<void> backspace() async => _editAmount((int rupees) => Option<int>.of(AmountInput.backspace(rupees)));

  /// Empties the amount (long-press ⌫).
  Future<void> clear() async => _editAmount((int _) => const Option<int>.of(0));

  /// Saves the bill as going out on [day] of each month; ignored while a save is in flight.
  Future<void> chooseDay(int day) async {
    final BillEditorState current = state;
    if (current is! BillEditorInProgress || current.stage != BillEditorStage.day || current.saving) {
      return;
    }
    emit(current.copyWith(saving: true));
    final BillInput input = BillInput(label: current.label, amount: Money.fromMajor(current.rupees), dueDay: day);
    final Either<Failure, RecurringRule> saved = await _save(input, current.kind).run();
    if (isClosed) {
      return;
    }
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

  /// Steps back one question: day → amount → name.
  ///
  /// Returns false on the name, where back should close the page.
  bool back() {
    final BillEditorState current = state;
    if (current is! BillEditorInProgress || current.stage == BillEditorStage.name) {
      return false;
    }
    emit(current.copyWith(stage: BillEditorStage.values[current.stage.index - 1]));
    return true;
  }

  TaskEither<Failure, RecurringRule> _save(BillInput input, Option<BillKind> kind) => _editing.match(
        () => _addBill(AddBillParams(input: input, kind: kind)),
        (RecurringRule rule) => _editBill(EditBillParams(rule: rule, input: input)),
      );

  void _editAmount(Option<int> Function(int rupees) edit) => _whenAt(
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
