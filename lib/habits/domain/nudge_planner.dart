import 'package:fpdart/fpdart.dart';

import '../../core/time/calendar_date.dart';
import '../../ledger/ledger.dart';
import 'entities/habit_index.dart';
import 'entities/nudge.dart';
import 'entities/nudge_state.dart';
import 'entities/usual_habit.dart';
import 'habit_candidates.dart';
import 'nudge_rules.dart';

/// Works out which daily nudges to arm (SPEC BR-22). Pure and synchronous.
abstract final class NudgePlanner {
  static const int _minutesPerHour = 60;

  /// The nudges to arm at [now]: today's if its time is still ahead, then tomorrow's, at most one
  /// a date and in date order.
  ///
  /// [index] describes today (BR-22.3): its `loggedToday` and `asked_on` cancel today's nudge, and
  /// tomorrow is planned as if nothing were logged, with tomorrow's day type. [nudgeStates] is keyed
  /// by category id, 0 for the general nudge, and a nudge for a date on or before its `restUntil` is
  /// skipped. [hasEnoughDays] is whether 10 days have a learned entry, which allows the general
  /// nudge (BR-22.2). Returns an empty list when [index] was built for another day than [now]'s.
  static List<Nudge> plan(
    HabitIndex index, {
    required DateTime now,
    required List<Category> categories,
    required Map<int, NudgeState> nudgeStates,
    required bool hasEnoughDays,
  }) {
    final CalendarDate today = CalendarDate.fromDateTime(now);
    // why: an index left over from yesterday has the wrong "logged today" and day type.
    if (index.builtOn != today) {
      return const <Nudge>[];
    }
    final _Facts facts = _Facts(
      index: index,
      shown: <int>{
        for (final Category category in categories.where((Category category) => !category.hidden)) category.id,
      },
      nudgeStates: nudgeStates,
      hasEnoughDays: hasEnoughDays,
    );
    return <Option<Nudge>>[
      _forDate(facts, today).filter((Nudge nudge) => nudge.at.isAfter(now)),
      _forDate(facts, today.addDays(1)),
    ].expand((Option<Nudge> nudge) => nudge.match(() => const <Nudge>[], (Nudge found) => <Nudge>[found])).toList();
  }

  static Option<Nudge> _forDate(_Facts facts, CalendarDate date) {
    // why: a missed-log line asked today covers today only (BR-22.4).
    if (HabitCandidates.askedOn(facts.index, date)) {
      return const Option<Nudge>.none();
    }
    final Option<Nudge> categoryNudge = Option<UsualHabit>.fromNullable(
      HabitCandidates.eligible(facts.index, date, shown: facts.shown)
          .where((UsualHabit habit) => !_resting(facts.nudgeStates, habit.categoryId, date))
          .where((UsualHabit habit) => _showMinute(habit) <= NudgeRules.latestMinute)
          .firstOrNull,
    ).map(
      (UsualHabit habit) => Nudge(
        date: date,
        categoryId: Option<int>.of(habit.categoryId),
        at: _at(date, _showMinute(habit)),
      ),
    );
    // why: the fallback is for people with no Regular habit at all; a habit that gives none
    // today (logged, resting, too late) must not turn into a general nudge (BR-22.2).
    return facts.index.habits.isNotEmpty ? categoryNudge : _general(facts, date);
  }

  static Option<Nudge> _general(_Facts facts, CalendarDate date) {
    // why: "logged today" describes the index's day only.
    final bool loggedToday = date == facts.index.builtOn && facts.index.loggedToday.isNotEmpty;
    final bool allowed =
        facts.hasEnoughDays && !loggedToday && !_resting(facts.nudgeStates, NudgeRules.generalCategoryId, date);
    return allowed
        ? Option<Nudge>.of(
            Nudge(date: date, categoryId: const Option<int>.none(), at: _at(date, NudgeRules.generalMinute)),
          )
        : const Option<Nudge>.none();
  }

  // why: a window that crosses midnight ends after 1440, so it is past the latest minute too (E123).
  static int _showMinute(UsualHabit habit) =>
      habit.window.startMinute + habit.window.lengthMinutes + NudgeRules.graceMinutes;

  static DateTime _at(CalendarDate date, int minuteOfDay) =>
      DateTime(date.year, date.month, date.day, minuteOfDay ~/ _minutesPerHour, minuteOfDay % _minutesPerHour);

  static bool _resting(Map<int, NudgeState> nudgeStates, int categoryId, CalendarDate date) =>
      Option<NudgeState>.fromNullable(nudgeStates[categoryId])
          .flatMap((NudgeState state) => state.restUntil)
          .match(() => false, (CalendarDate last) => !date.isAfter(last));
}

/// What one planning run reads, grouped so the helpers take few parameters.
final class _Facts {
  const _Facts({required this.index, required this.shown, required this.nudgeStates, required this.hasEnoughDays});

  final HabitIndex index;
  final Set<int> shown;
  final Map<int, NudgeState> nudgeStates;
  final bool hasEnoughDays;
}
