import 'package:equatable/equatable.dart';

/// What the person did on the *Put in extra* keypad (D120).
sealed class PutInExtraEvent extends Equatable {
  const PutInExtraEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The sheet opened: load today's summary for the cap and the preview.
final class PutInExtraLoadRequested extends PutInExtraEvent {
  const PutInExtraLoadRequested();
}

/// A digit key was tapped.
final class PutInExtraKeyPressed extends PutInExtraEvent {
  const PutInExtraKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// ⌫ was tapped.
final class PutInExtraBackspacePressed extends PutInExtraEvent {
  const PutInExtraBackspacePressed();
}

/// ⌫ was long-pressed: the amount goes back to ₹0.
final class PutInExtraCleared extends PutInExtraEvent {
  const PutInExtraCleared();
}

/// *Save* was tapped.
final class PutInExtraSavePressed extends PutInExtraEvent {
  const PutInExtraSavePressed();
}
