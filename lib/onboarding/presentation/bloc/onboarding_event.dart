import 'package:equatable/equatable.dart';

import '../../../core/time/pay_rule.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/setup_labels.dart';
import 'onboarding_state.dart';

/// What the user does during onboarding.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Onboarding opened; load a saved draft or start at step 1.
final class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

/// The user pressed keypad [key] (`0`–`9`, `00`) for the income or the open bill.
final class OnboardingKeyPressed extends OnboardingEvent {
  const OnboardingKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// The user pressed ⌫.
final class OnboardingBackspacePressed extends OnboardingEvent {
  const OnboardingBackspacePressed();
}

/// The user long-pressed ⌫ to empty the amount.
final class OnboardingCleared extends OnboardingEvent {
  const OnboardingCleared();
}

/// The user tapped Next on step 1 or on a bill's amount.
final class OnboardingNextPressed extends OnboardingEvent {
  const OnboardingNextPressed();
}

/// The user asked for the day-of-month or weekday [picker] on step 2.
final class OnboardingPickerOpened extends OnboardingEvent {
  const OnboardingPickerOpened(this.picker);

  final PaydayPicker picker;

  @override
  List<Object?> get props => <Object?>[picker];
}

/// The user answered step 2 with [rule].
final class OnboardingPayRuleChosen extends OnboardingEvent {
  const OnboardingPayRuleChosen(this.rule);

  final PayRule rule;

  @override
  List<Object?> get props => <Object?>[rule];
}

/// The user tapped the bill chip for [kind] on step 3.
final class OnboardingBillOpened extends OnboardingEvent {
  const OnboardingBillOpened(this.kind);

  final BillKind kind;

  @override
  List<Object?> get props => <Object?>[kind];
}

/// The user chose [day] of the month as the open bill's due day.
final class OnboardingBillDayChosen extends OnboardingEvent {
  const OnboardingBillDayChosen(this.day);

  final int day;

  @override
  List<Object?> get props => <Object?>[day];
}

/// The user removed the bill of [kind].
final class OnboardingBillRemoved extends OnboardingEvent {
  const OnboardingBillRemoved(this.kind);

  final BillKind kind;

  @override
  List<Object?> get props => <Object?>[kind];
}

/// The user pressed back somewhere other than step 1.
final class OnboardingBackPressed extends OnboardingEvent {
  const OnboardingBackPressed();
}

/// The user tapped Done or Skip on step 3; [labels] name the new rules.
final class OnboardingFinishRequested extends OnboardingEvent {
  const OnboardingFinishRequested(this.labels);

  final SetupLabels labels;

  @override
  List<Object?> get props => <Object?>[labels];
}
