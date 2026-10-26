import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../ledger/ledger.dart';
import '../../domain/entities/onboarding_draft.dart';

/// Which extra picker step 2 is showing.
enum PaydayPicker {
  none,

  /// Days 1–31, for "Pick a date".
  dayOfMonth,

  /// Monday–Sunday, for "Every week".
  weekday,
}

/// Which half of the bill editor is showing: the amount keypad or the due-day grid.
enum BillStage {
  amount,
  day,
}

/// The bill being added in step 3 (FR-ON-4): a mini keypad, then its due day.
final class BillEditor extends Equatable {
  const BillEditor({required this.kind, this.rupees = 0, this.stage = BillStage.amount});

  final BillKind kind;
  final int rupees;
  final BillStage stage;

  /// Returns a copy with the given fields replaced.
  BillEditor copyWith({int? rupees, BillStage? stage}) =>
      BillEditor(kind: kind, rupees: rupees ?? this.rupees, stage: stage ?? this.stage);

  @override
  List<Object?> get props => <Object?>[kind, rupees, stage];
}

/// The onboarding screen's situation.
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loading a saved draft; nothing to show yet.
final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Answering the questions. [rejections] counts refused key presses so the amount can shake;
/// [saveFailed] shows "Couldn't save. Try again." after a failed finish.
final class OnboardingInProgress extends OnboardingState {
  const OnboardingInProgress({
    required this.draft,
    this.picker = PaydayPicker.none,
    this.billEditor = const Option<BillEditor>.none(),
    this.rejections = 0,
    this.saveFailed = false,
  });

  final OnboardingDraft draft;
  final PaydayPicker picker;
  final Option<BillEditor> billEditor;
  final int rejections;
  final bool saveFailed;

  /// Returns a copy with the given fields replaced; [saveFailed] resets unless passed.
  OnboardingInProgress copyWith({
    OnboardingDraft? draft,
    PaydayPicker? picker,
    Option<BillEditor>? billEditor,
    int? rejections,
    bool saveFailed = false,
  }) =>
      OnboardingInProgress(
        draft: draft ?? this.draft,
        picker: picker ?? this.picker,
        billEditor: billEditor ?? this.billEditor,
        rejections: rejections ?? this.rejections,
        saveFailed: saveFailed,
      );

  @override
  List<Object?> get props => <Object?>[draft, picker, billEditor, rejections, saveFailed];
}

/// Writing the setup; inputs are disabled.
final class OnboardingFinishing extends OnboardingState {
  const OnboardingFinishing(this.draft);

  final OnboardingDraft draft;

  @override
  List<Object?> get props => <Object?>[draft];
}

/// Everything is saved; the app moves to Home.
final class OnboardingDone extends OnboardingState {
  const OnboardingDone();
}
