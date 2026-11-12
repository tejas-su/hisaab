import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/habit_index.dart';
import '../../domain/entities/usual_add.dart';

/// What the app knows about the user's habits right now.
sealed class HabitsState extends Equatable {
  const HabitsState();
}

/// No habits have been worked out yet; the Add tray opens without a pill.
final class HabitsLoading extends HabitsState {
  /// The state before the first load that succeeds.
  const HabitsLoading();

  @override
  List<Object?> get props => <Object?>[];
}

/// Today's habits are known; the Add tray reads [index] when it opens.
final class HabitsReady extends HabitsState {
  /// Holds [index], and the pill add to offer Undo for when one was just made.
  const HabitsReady(this.index, {this.added = const Option<UsualAdd>.none()});

  /// The habits, the categories logged today and the quiet states, as of the last load.
  final HabitIndex index;

  /// The pill add to show "Added ₹20 to Chai · Undo" for. [Some] in the one state emitted when
  /// the add is reported, [None] in every other.
  final Option<UsualAdd> added;

  @override
  List<Object?> get props => <Object?>[index, added];
}
