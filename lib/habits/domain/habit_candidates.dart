import 'package:fpdart/fpdart.dart';

import '../../core/time/calendar_date.dart';
import 'detectors/usual_spend_detector.dart';
import 'entities/day_type.dart';
import 'entities/habit_index.dart';
import 'entities/suggestion_state.dart';
import 'entities/usual_habit.dart';
import 'suggestion_gate.dart';

/// The habits the missed-log line (SPEC BR-17) and the daily nudge (BR-22.1) may ask about, worked
/// out in one place so the two never disagree. Pure and synchronous.
abstract final class HabitCandidates {
  /// The habits of [date]'s day type that may be asked about on [date], best first.
  ///
  /// A habit qualifies when it is not fading, its category is in [shown], its gate is open on
  /// [date] and, when [date] is the day [index] was built for, its category has no entry today.
  /// Order is [UsualSpendDetector.rank].
  static List<UsualHabit> eligible(HabitIndex index, CalendarDate date, {required Set<int> shown}) =>
      index.habits
          .where((UsualHabit habit) => habit.dayType == DayType.of(date) && !habit.fading)
          .where((UsualHabit habit) => shown.contains(habit.categoryId))
          // why: "logged today" describes the index's day only; a later day assumes nothing is logged.
          .where((UsualHabit habit) => date != index.builtOn || !index.loggedToday.contains(habit.categoryId))
          .where((UsualHabit habit) => _open(index, habit.categoryId, date))
          .toList()
        ..sort(UsualSpendDetector.rank);

  /// Whether the missed-log line was asked on [day] for any category (D172).
  static bool askedOn(HabitIndex index, CalendarDate day) => index.states.values.any(
        (SuggestionState state) => state.askedOn.match(() => false, (CalendarDate asked) => asked == day),
      );

  static bool _open(HabitIndex index, int categoryId, CalendarDate date) =>
      SuggestionGate.statusOf(Option<SuggestionState>.fromNullable(index.states[categoryId]), today: date) ==
      GateStatus.open;
}
