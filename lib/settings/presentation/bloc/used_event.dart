import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// What the person did on the *Used some of it* keypad (BR-19, AC-Y6).
sealed class UsedEvent extends Equatable {
  const UsedEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The question opened for [saving]: read what is set aside in it.
final class UsedLoadRequested extends UsedEvent {
  const UsedLoadRequested(this.saving);

  final RecurringRule saving;

  @override
  List<Object?> get props => <Object?>[saving];
}

/// A digit key (`0` to `9` or `00`) was tapped.
final class UsedKeyPressed extends UsedEvent {
  const UsedKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// ⌫ was tapped.
final class UsedBackspacePressed extends UsedEvent {
  const UsedBackspacePressed();
}

/// ⌫ was long-pressed: the amount goes back to nothing typed.
final class UsedCleared extends UsedEvent {
  const UsedCleared();
}

/// *All of it* was tapped: fills everything set aside, or clears the amount when it already does.
final class UsedAllPressed extends UsedEvent {
  const UsedAllPressed();
}

/// *Save* was tapped.
final class UsedSavePressed extends UsedEvent {
  const UsedSavePressed();
}

/// The person went back to the saving's sheet: unsaved typing is dropped (AC-5).
final class UsedReset extends UsedEvent {
  const UsedReset();
}
