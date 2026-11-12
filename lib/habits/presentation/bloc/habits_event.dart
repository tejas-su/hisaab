import 'package:equatable/equatable.dart';

import '../../domain/entities/usual_add.dart';

/// What happens to the app's *your usual* habits.
sealed class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The main screen opened or resumed, midnight passed, Settings closed, or the ledger changed:
/// work out today's habits again.
final class HabitsLoadRequested extends HabitsEvent {
  /// Asks for today's habits.
  const HabitsLoadRequested();
}

/// The Add tray closed after a one-tap save from the pill; the app offers to undo it (BR-10).
final class HabitsUsualAdded extends HabitsEvent {
  /// Reports the entry the pill saved.
  const HabitsUsualAdded(this.added);

  /// The saved entry and its category.
  final UsualAdd added;

  @override
  List<Object?> get props => <Object?>[added];
}

/// The user tapped Undo on "Added ₹20 to Chai".
final class HabitsUsualUndoRequested extends HabitsEvent {
  /// Asks to undo [added].
  const HabitsUsualUndoRequested(this.added);

  /// The pill add to take back.
  final UsualAdd added;

  @override
  List<Object?> get props => <Object?>[added];
}
