import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import 'day_type.dart';
import 'suggestion_state.dart';
import 'usual_habit.dart';

/// Everything *your usual* knows on one day (SPEC BR-17), worked out ahead so opening the Add
/// tray reads nothing from the database.
final class HabitIndex extends Equatable {
  /// Creates the index of the day [builtOn].
  const HabitIndex({
    required this.builtOn,
    required this.habits,
    required this.loggedToday,
    required this.states,
  });

  /// An index with no habits, for an empty ledger or before the first load.
  factory HabitIndex.empty(CalendarDate today) => HabitIndex(
        builtOn: today,
        habits: const <UsualHabit>[],
        loggedToday: const <int>{},
        states: const <int, SuggestionState>{},
      );

  /// The day the index was worked out for; it suggests nothing on any other day.
  final CalendarDate builtOn;

  /// Every Regular habit, at most one per category and day type.
  final List<UsualHabit> habits;

  /// The ids of the categories with an entry dated [builtOn], typed or posted (E65).
  final Set<int> loggedToday;

  /// The quiet, rest and forget state of each category that has one, by category id.
  final Map<int, SuggestionState> states;

  /// The habit of category [categoryId] to show in Settings (FR-SE-2 AC-6).
  ///
  /// Returns [Some] with the habit of the day type [preferring], else the habit of the other day
  /// type, or [None] when the category has no habit.
  Option<UsualHabit> habitFor(int categoryId, {required DayType preferring}) {
    final List<UsualHabit> own = habits.where((UsualHabit habit) => habit.categoryId == categoryId).toList();
    return Option<UsualHabit>.fromNullable(
      own.where((UsualHabit habit) => habit.dayType == preferring).firstOrNull ?? own.firstOrNull,
    );
  }

  @override
  List<Object?> get props => <Object?>[builtOn, habits, loggedToday, states];
}
