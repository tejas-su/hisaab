import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';
import '../entities/day_type.dart';
import '../entities/habit_index.dart';
import '../entities/suggestion_state.dart';
import '../entities/usual_habit.dart';
import '../entities/usual_spend.dart';
import '../suggestion_gate.dart';
import '../time_profile.dart';

/// Picks the *your usual* to offer when the Add tray opens (SPEC BR-17). Pure and synchronous, so
/// it can run in the tray's first frame.
abstract final class UsualSpendDetector {
  /// The spend to offer at [now], given the day's [index] and the [categories] the tray shows.
  ///
  /// Returns [Some] when a habit of today's day type has [now] inside its window, is not fading,
  /// quiet or resting, and its category is shown and has no entry dated today. When two qualify,
  /// the higher share of days wins, then the more recent hit, then the lower category id.
  ///
  /// Returns [None] otherwise, and always when [index] was built for another day than [now]'s.
  static Option<UsualSpend> suggest(HabitIndex index, {required DateTime now, required List<Category> categories}) {
    final CalendarDate today = CalendarDate.fromDateTime(now);
    // why: an index left over from yesterday (the app stayed open past midnight) has the wrong
    // "logged today" and the wrong day type; no pill is better than a wrong one.
    if (index.builtOn != today) {
      return const Option<UsualSpend>.none();
    }
    final int minute = TimeProfile.minuteOf(now);
    final Map<int, Category> shown = <int, Category>{
      for (final Category category in categories.where((Category category) => !category.hidden)) category.id: category,
    };
    final List<UsualHabit> offered = index.habits
        .where((UsualHabit habit) => habit.dayType == DayType.of(today) && !habit.fading)
        .where((UsualHabit habit) => habit.window.contains(minute))
        .where((UsualHabit habit) => shown.containsKey(habit.categoryId))
        .where((UsualHabit habit) => !index.loggedToday.contains(habit.categoryId))
        .where((UsualHabit habit) => _open(index, habit.categoryId, today))
        .toList()
      ..sort(rank);
    return Option<UsualHabit>.fromNullable(offered.firstOrNull).flatMap(
      (UsualHabit habit) => Option<Category>.fromNullable(shown[habit.categoryId]).map(
        (Category category) => UsualSpend(category: category, amount: habit.amount),
      ),
    );
  }

  static bool _open(HabitIndex index, int categoryId, CalendarDate today) =>
      SuggestionGate.statusOf(Option<SuggestionState>.fromNullable(index.states[categoryId]), today: today) ==
      GateStatus.open;

  /// Orders the habit to offer first: the higher share of hit days, then the later hit, then the
  /// lower category id, so the pick is never arbitrary.
  static int rank(UsualHabit a, UsualHabit b) {
    // why: cross-multiplied, so two shares are compared without dividing.
    final int byShare = (b.hitDays * a.activeDays).compareTo(a.hitDays * b.activeDays);
    if (byShare != 0) {
      return byShare;
    }
    final int byLastHit = b.lastHit.compareTo(a.lastHit);
    return byLastHit != 0 ? byLastHit : a.categoryId.compareTo(b.categoryId);
  }
}
