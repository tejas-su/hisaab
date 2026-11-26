import 'package:equatable/equatable.dart';

/// What happens in the *Can I afford it?* sheet (SPEC FR-SP-9).
sealed class AffordEvent extends Equatable {
  const AffordEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The user typed in the item's name field on step 1.
final class AffordNameChanged extends AffordEvent {
  const AffordNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

/// The user tapped a digit key ('0' to '9' or '00') on the price or the saved amount.
final class AffordKeyPressed extends AffordEvent {
  const AffordKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// The user tapped ⌫ on the keypad.
final class AffordBackspacePressed extends AffordEvent {
  const AffordBackspacePressed();
}

/// The user long-pressed ⌫ to clear the amount.
final class AffordCleared extends AffordEvent {
  const AffordCleared();
}

/// The user tapped *Next* on step 1.
final class AffordNextPressed extends AffordEvent {
  const AffordNextPressed();
}

/// The user picked *Yes* ([saved] true) or *Nothing yet* on step 2.
final class AffordHaveChosen extends AffordEvent {
  const AffordHaveChosen(this.saved);

  final bool saved;

  @override
  List<Object?> get props => <Object?>[saved];
}

/// The user tapped *See the answer* on step 2.
final class AffordAnswerRequested extends AffordEvent {
  const AffordAnswerRequested();
}

/// The user opened or closed *Other ways* under the answer.
final class AffordWaysToggled extends AffordEvent {
  const AffordWaysToggled();
}

/// The user tapped *Start saving ₹X a month* on a *Not yet* answer.
final class AffordStartSavingPressed extends AffordEvent {
  const AffordStartSavingPressed();
}

/// The user tapped Back, system back or Escape: one step back, or close on step 1.
final class AffordBackPressed extends AffordEvent {
  const AffordBackPressed();
}
