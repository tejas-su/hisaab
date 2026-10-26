import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/time/pay_rule.dart';
import '../../domain/entities/bill_draft.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/entities/setup_labels.dart';
import '../../domain/repository/onboarding_draft_repository.dart';
import '../../domain/usecase/complete_onboarding.dart';
import 'onboarding_state.dart';

/// Owns the three onboarding answers (SPEC FR-ON-1 to FR-ON-6), driven by the onboarding page.
///
/// Every change to the answers is saved as a draft so leaving midway resumes at the same step.
/// The keypad feeds the income on step 1 and the open bill on step 3.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required this._drafts, required this._completeOnboarding, required this._haptics})
      : super(const OnboardingLoading());

  final OnboardingDraftRepository _drafts;
  final CompleteOnboarding _completeOnboarding;
  final Haptics _haptics;

  /// Loads a saved draft, or starts at step 1.
  Future<void> start() async {
    final Either<Failure, Option<OnboardingDraft>> loaded = await _drafts.load().run();
    if (isClosed) {
      return;
    }
    final OnboardingDraft draft = loaded.match(
      (Failure failure) {
        AppLogger.log(tag: 'onboarding.draft_load_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        return const OnboardingDraft();
      },
      (Option<OnboardingDraft> saved) => saved.getOrElse(() => const OnboardingDraft()),
    );
    emit(OnboardingInProgress(draft: draft));
  }

  /// Types [key] (`0`–`9`, `00`) into the income or the open bill's amount.
  Future<void> pressKey(String key) => _editAmount((int rupees) => AmountInput.append(rupees, key));

  /// Removes the last digit.
  Future<void> backspace() => _editAmount((int rupees) => Option<int>.of(AmountInput.backspace(rupees)));

  /// Empties the amount (long-press ⌫).
  Future<void> clear() => _editAmount((int _) => const Option<int>.of(0));

  /// Moves on from step 1, or from a bill's amount to its due day; ignored at ₹0.
  Future<void> next() async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return;
    }
    final BillEditor? editor = current.billEditor.toNullable();
    if (editor != null) {
      if (editor.rupees > 0) {
        emit(current.copyWith(billEditor: Option<BillEditor>.of(editor.copyWith(stage: BillStage.day))));
      }
      return;
    }
    if (current.draft.step == OnboardingStep.income && !current.draft.income.isZero) {
      await _saveDraft(current, current.draft.copyWith(step: OnboardingStep.payday));
    }
  }

  /// Shows the day-of-month or weekday picker for step 2.
  void openPicker(PaydayPicker picker) => _whenInProgress((OnboardingInProgress current) => emit(current.copyWith(picker: picker)));

  /// Answers step 2 and moves to the bills.
  Future<void> choosePayRule(PayRule rule) async {
    final OnboardingState current = state;
    if (current is OnboardingInProgress) {
      await _saveDraft(
        current.copyWith(picker: PaydayPicker.none),
        current.draft.copyWith(payRule: Option<PayRule>.of(rule), step: OnboardingStep.bills),
      );
    }
  }

  /// Opens the mini keypad for [kind], prefilled when that bill was already added.
  void openBill(BillKind kind) => _whenInProgress((OnboardingInProgress current) {
        final int rupees = current.draft.bills
            .where((BillDraft bill) => bill.kind == kind)
            .map((BillDraft bill) => bill.amount.floorMajor)
            .firstOrNull ??
            0;
        emit(current.copyWith(billEditor: Option<BillEditor>.of(BillEditor(kind: kind, rupees: rupees))));
      });

  /// Saves the open bill as due on [day] of each month.
  Future<void> chooseBillDay(int day) async {
    final OnboardingState current = state;
    final BillEditor? editor = current is OnboardingInProgress ? current.billEditor.toNullable() : null;
    if (current is OnboardingInProgress && editor != null) {
      final BillDraft bill = BillDraft(kind: editor.kind, amount: Money.fromMajor(editor.rupees), dueDay: day);
      await _saveDraft(current.copyWith(billEditor: const Option<BillEditor>.none()), current.draft.withBill(bill));
    }
  }

  /// Drops the bill of [kind] and closes its editor.
  Future<void> removeBill(BillKind kind) async {
    final OnboardingState current = state;
    if (current is OnboardingInProgress) {
      await _saveDraft(current.copyWith(billEditor: const Option<BillEditor>.none()), current.draft.withoutBill(kind));
    }
  }

  /// Steps back one level: bill day → bill amount → bills list → payday picker → previous step.
  ///
  /// Returns false on step 1, where back should leave the app.
  Future<bool> back() async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return false;
    }
    final BillEditor? editor = current.billEditor.toNullable();
    if (editor != null) {
      emit(
        current.copyWith(
          billEditor: editor.stage == BillStage.day
              ? Option<BillEditor>.of(editor.copyWith(stage: BillStage.amount))
              : const Option<BillEditor>.none(),
        ),
      );
      return true;
    }
    if (current.picker != PaydayPicker.none) {
      emit(current.copyWith(picker: PaydayPicker.none));
      return true;
    }
    return switch (current.draft.step) {
      OnboardingStep.income => false,
      OnboardingStep.payday => _stepBackTo(current, OnboardingStep.income),
      OnboardingStep.bills => _stepBackTo(current, OnboardingStep.payday),
    };
  }

  /// Finishes onboarding with the bills added so far (also "Skip"); [labels] name the new rules.
  Future<void> finish(SetupLabels labels) async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return;
    }
    emit(OnboardingFinishing(current.draft));
    final Either<Failure, Unit> result =
        await _completeOnboarding(CompleteOnboardingParams(draft: current.draft, labels: labels)).run();
    if (isClosed) {
      return;
    }
    result.match(
      (Failure failure) {
        AppLogger.log(tag: 'onboarding.finish_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        unawaited(_haptics.reject());
        emit(current.copyWith(saveFailed: true));
      },
      (Unit _) {
        unawaited(_haptics.success());
        emit(const OnboardingDone());
      },
    );
  }

  Future<bool> _stepBackTo(OnboardingInProgress current, OnboardingStep step) async {
    await _saveDraft(current, current.draft.copyWith(step: step));
    return true;
  }

  Future<void> _editAmount(Option<int> Function(int rupees) edit) async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return;
    }
    final BillEditor? editor = current.billEditor.toNullable();
    if (editor != null) {
      _applyEdit(current, editor.rupees, edit, (int rupees) {
        emit(current.copyWith(billEditor: Option<BillEditor>.of(editor.copyWith(rupees: rupees))));
        return Future<void>.value();
      });
      return;
    }
    if (current.draft.step == OnboardingStep.income) {
      await _applyEdit(
        current,
        current.draft.income.floorMajor,
        edit,
        (int rupees) => _saveDraft(current, current.draft.copyWith(income: Money.fromMajor(rupees))),
      );
    }
  }

  Future<void> _applyEdit(
    OnboardingInProgress current,
    int rupees,
    Option<int> Function(int rupees) edit,
    Future<void> Function(int rupees) apply,
  ) =>
      edit(rupees).match(
        () {
          unawaited(_haptics.reject());
          emit(current.copyWith(rejections: current.rejections + 1));
          return Future<void>.value();
        },
        (int updated) {
          unawaited(_haptics.tick());
          return apply(updated);
        },
      );

  Future<void> _saveDraft(OnboardingInProgress current, OnboardingDraft draft) async {
    emit(current.copyWith(draft: draft));
    final Either<Failure, Unit> saved = await _drafts.save(draft).run();
    saved.mapLeft(
      (Failure failure) => AppLogger.log(
        tag: 'onboarding.draft_save_failed',
        data: <String, Object?>{'type': failure.runtimeType.toString()},
      ),
    );
  }

  void _whenInProgress(void Function(OnboardingInProgress current) action) {
    final OnboardingState current = state;
    if (current is OnboardingInProgress) {
      action(current);
    }
  }
}
