import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';
import '../entities/day_type.dart';
import '../entities/habit_index.dart';
import '../entities/missed_log.dart';
import '../entities/suggestion_state.dart';
import '../entities/usual_habit.dart';
import '../habit_rules.dart';
import '../suggestion_gate.dart';
import '../time_profile.dart';
import 'usual_spend_detector.dart';

/// Picks the habit the missed-log line asks about (SPEC BR-17, FR-HO-3). Pure and synchronous.
abstract final class MissedLogDetector {
  /// Minutes after a window's end before the line may ask (BR-17 rule 3).
  static const int graceMinutes = 90;

  /// The habit to ask about at [now], given the day's [index] and the [categories] Home shows.
  ///
  /// The day type comes from [now]. `asked_on` arrives inside `index.states`. Returns [Some] when
  /// no category was asked today and a Regular habit of today's day type, not fading and with an
  /// open gate, has its category shown with no entry today, and [now] is at least 90 minutes after
  /// its window's end. When two qualify the pill's tie-break applies ([UsualSpendDetector.rank]).
  ///
  /// Returns [None] otherwise, and always when [index] was built for another day than [now]'s.
  static Option<MissedLog> suggest(HabitIndex index, {required DateTime now, required List<Category> categories}) {
    final CalendarDate today = CalendarDate.fromDateTime(now);
    // why: an index left over from yesterday has the wrong "logged today" and day type.
    if (index.builtOn != today || _askedToday(index, today)) {
      return const Option<MissedLog>.none();
    }
    final int minute = TimeProfile.minuteOf(now);
    final Map<int, Category> shown = <int, Category>{
      for (final Category category in categories.where((Category category) => !category.hidden)) category.id: category,
    };
    final List<UsualHabit> candidates = index.habits
        .where((UsualHabit habit) => habit.dayType == DayType.of(today) && !habit.fading)
        .where((UsualHabit habit) => shown.containsKey(habit.categoryId))
        .where((UsualHabit habit) => !index.loggedToday.contains(habit.categoryId))
        .where((UsualHabit habit) => _open(index, habit.categoryId, today))
        .where((UsualHabit habit) => _longAfterWindow(habit, minute))
        .toList()
      ..sort(UsualSpendDetector.rank);
    return Option<UsualHabit>.fromNullable(candidates.firstOrNull).flatMap(
      (UsualHabit habit) => Option<Category>.fromNullable(shown[habit.categoryId]).map(
        (Category category) => MissedLog(category: category, window: habit.window, amount: habit.amount),
      ),
    );
  }

  static bool _askedToday(HabitIndex index, CalendarDate today) => index.states.values.any(
        (SuggestionState state) => state.askedOn.match(() => false, (CalendarDate day) => day == today),
      );

  static bool _open(HabitIndex index, int categoryId, CalendarDate today) =>
      SuggestionGate.statusOf(Option<SuggestionState>.fromNullable(index.states[categoryId]), today: today) ==
      GateStatus.open;

  static bool _longAfterWindow(UsualHabit habit, int minuteOfDay) {
    final int end = habit.window.startMinute + habit.window.lengthMinutes;
    // why: a window that crosses midnight never asks, its 90 minutes would fall in the small hours
    // (E103). A window ending later than 22:30 can't pass the check below on the same date.
    return end <= HabitRules.minutesPerDay && minuteOfDay >= end + graceMinutes;
  }
}
