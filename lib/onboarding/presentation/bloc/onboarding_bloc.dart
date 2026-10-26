import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/time/pay_rule.dart';
import '../../domain/entities/bill_draft.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/repository/onboarding_draft_repository.dart';
import '../../domain/usecase/complete_onboarding.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Owns the three onboarding answers (SPEC FR-ON-1 to FR-ON-6), driven by the onboarding page.
///
/// Every change to the answers is saved as a draft so leaving midway resumes at the same step.
/// The keypad feeds the income on step 1 and the open bill on step 3.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required this._drafts, required this._completeOnboarding, required this._haptics})
      : super(const OnboardingLoading()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingKeyPressed>(
      (OnboardingKeyPressed event, Emitter<OnboardingState> emit) =>
          _editAmount(emit, (int rupees) => AmountInput.append(rupees, event.key)),
    );
    on<OnboardingBackspacePressed>(
      (OnboardingBackspacePressed event, Emitter<OnboardingState> emit) =>
          _editAmount(emit, (int rupees) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<OnboardingCleared>(
      (OnboardingCleared event, Emitter<OnboardingState> emit) => _editAmount(emit, (int _) => const Option<int>.of(0)),
    );
    on<OnboardingNextPressed>(_onNextPressed);
    on<OnboardingPickerOpened>(_onPickerOpened);
    on<OnboardingPayRuleChosen>(_onPayRuleChosen);
    on<OnboardingBillOpened>(_onBillOpened);
    on<OnboardingBillDayChosen>(_onBillDayChosen);
    on<OnboardingBillRemoved>(_onBillRemoved);
    on<OnboardingBackPressed>(_onBackPressed);
    // why: a second Done tap while the first save is in flight must not set up the ledger twice.
    on<OnboardingFinishRequested>(_onFinishRequested, transformer: droppable());
  }

  final OnboardingDraftRepository _drafts;
  final CompleteOnboarding _completeOnboarding;
  final Haptics _haptics;

  Future<void> _onStarted(OnboardingStarted event, Emitter<OnboardingState> emit) async {
    final Either<Failure, Option<OnboardingDraft>> loaded = await _drafts.load().run();
    final OnboardingDraft draft = loaded.match(
      (Failure failure) {
        AppLogger.log(tag: 'onboarding.draft_load_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        return const OnboardingDraft();
      },
      (Option<OnboardingDraft> saved) => saved.getOrElse(() => const OnboardingDraft()),
    );
    emit(OnboardingInProgress(draft: draft));
  }

  /// Moves on from step 1, or from a bill's amount to its due day; ignored at ₹0.
  Future<void> _onNextPressed(OnboardingNextPressed event, Emitter<OnboardingState> emit) async {
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
      await _saveDraft(emit, current, current.draft.copyWith(step: OnboardingStep.payday));
    }
  }

  void _onPickerOpened(OnboardingPickerOpened event, Emitter<OnboardingState> emit) =>
      _whenInProgress((OnboardingInProgress current) => emit(current.copyWith(picker: event.picker)));

  Future<void> _onPayRuleChosen(OnboardingPayRuleChosen event, Emitter<OnboardingState> emit) async {
    final OnboardingState current = state;
    if (current is OnboardingInProgress) {
      await _saveDraft(
        emit,
        current.copyWith(picker: PaydayPicker.none),
        current.draft.copyWith(payRule: Option<PayRule>.of(event.rule), step: OnboardingStep.bills),
      );
    }
  }

  /// Opens the mini keypad, prefilled when that bill was already added.
  void _onBillOpened(OnboardingBillOpened event, Emitter<OnboardingState> emit) =>
      _whenInProgress((OnboardingInProgress current) {
        final int rupees = current.draft.bills
                .where((BillDraft bill) => bill.kind == event.kind)
                .map((BillDraft bill) => bill.amount.floorMajor)
                .firstOrNull ??
            0;
        emit(current.copyWith(billEditor: Option<BillEditor>.of(BillEditor(kind: event.kind, rupees: rupees))));
      });

  Future<void> _onBillDayChosen(OnboardingBillDayChosen event, Emitter<OnboardingState> emit) async {
    final OnboardingState current = state;
    final BillEditor? editor = current is OnboardingInProgress ? current.billEditor.toNullable() : null;
    if (current is OnboardingInProgress && editor != null) {
      final BillDraft bill = BillDraft(kind: editor.kind, amount: Money.fromMajor(editor.rupees), dueDay: event.day);
      await _saveDraft(emit, current.copyWith(billEditor: const Option<BillEditor>.none()), current.draft.withBill(bill));
    }
  }

  Future<void> _onBillRemoved(OnboardingBillRemoved event, Emitter<OnboardingState> emit) async {
    final OnboardingState current = state;
    if (current is OnboardingInProgress) {
      await _saveDraft(emit, current.copyWith(billEditor: const Option<BillEditor>.none()), current.draft.withoutBill(event.kind));
    }
  }

  /// Steps back one level: bill day → bill amount → bills list → payday picker → previous step.
  /// On step 1 nothing changes; the page leaves the app instead.
  Future<void> _onBackPressed(OnboardingBackPressed event, Emitter<OnboardingState> emit) async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return;
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
      return;
    }
    if (current.picker != PaydayPicker.none) {
      emit(current.copyWith(picker: PaydayPicker.none));
      return;
    }
    await switch (current.draft.step) {
      OnboardingStep.income => Future<void>.value(),
      OnboardingStep.payday => _saveDraft(emit, current, current.draft.copyWith(step: OnboardingStep.income)),
      OnboardingStep.bills => _saveDraft(emit, current, current.draft.copyWith(step: OnboardingStep.payday)),
    };
  }

  /// Finishes onboarding with the bills added so far (also "Skip").
  Future<void> _onFinishRequested(OnboardingFinishRequested event, Emitter<OnboardingState> emit) async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return;
    }
    emit(OnboardingFinishing(current.draft));
    final Either<Failure, Unit> result =
        await _completeOnboarding(CompleteOnboardingParams(draft: current.draft, labels: event.labels)).run();
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

  Future<void> _editAmount(Emitter<OnboardingState> emit, Option<int> Function(int rupees) edit) async {
    final OnboardingState current = state;
    if (current is! OnboardingInProgress) {
      return;
    }
    final BillEditor? editor = current.billEditor.toNullable();
    if (editor != null) {
      await _applyEdit(emit, current, editor.rupees, edit, (int rupees) {
        emit(current.copyWith(billEditor: Option<BillEditor>.of(editor.copyWith(rupees: rupees))));
        return Future<void>.value();
      });
      return;
    }
    if (current.draft.step == OnboardingStep.income) {
      await _applyEdit(
        emit,
        current,
        current.draft.income.floorMajor,
        edit,
        (int rupees) => _saveDraft(emit, current, current.draft.copyWith(income: Money.fromMajor(rupees))),
      );
    }
  }

  Future<void> _applyEdit(
    Emitter<OnboardingState> emit,
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

  // why: the answer is emitted before the save, so the screen keeps it even if the save fails.
  Future<void> _saveDraft(Emitter<OnboardingState> emit, OnboardingInProgress current, OnboardingDraft draft) async {
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
