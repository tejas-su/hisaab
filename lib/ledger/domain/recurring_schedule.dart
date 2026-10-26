import '../../core/time/calendar_date.dart';
import 'entities/frequency.dart';
import 'entities/schedule.dart';

/// Pure date maths for recurring rules (SPEC BR-9): the next due date, the first due date on or
/// after a day, and every due date in a range.
///
/// Monthly and yearly dates clamp to short months exactly like paydays (SPEC BR-1), and always
/// return to the anchor's day afterwards, so a rule on the 31st goes 28 Feb → 31 Mar.
abstract final class RecurringSchedule {
  static const int _daysInWeek = 7;
  static const int _daysInFortnight = 14;

  /// The due date that follows [occurrence].
  static CalendarDate next(Schedule schedule, CalendarDate occurrence) => switch (schedule.frequency) {
        Frequency.weekly => occurrence.addDays(_daysInWeek),
        Frequency.biweekly => occurrence.addDays(_daysInFortnight),
        Frequency.monthly => _monthlyIn(schedule, occurrence.year, occurrence.month + 1),
        Frequency.yearly => _yearlyIn(schedule, occurrence.year + 1),
      };

  /// The first due date that is [date] or later.
  static CalendarDate firstOnOrAfter(Schedule schedule, CalendarDate date) => switch (schedule.frequency) {
        Frequency.weekly => _nextInPhase(schedule.anchor, date, _daysInWeek),
        Frequency.biweekly => _nextInPhase(schedule.anchor, date, _daysInFortnight),
        Frequency.monthly => _notBefore(date, _monthlyIn(schedule, date.year, date.month), schedule),
        Frequency.yearly => _notBefore(date, _yearlyIn(schedule, date.year), schedule),
      };

  /// The first due date after [today] that the engine hasn't posted, for a rule whose next
  /// unposted date is [nextDue].
  // why: anything due today or earlier is the engine's job (BR-3, BR-9), so a stale next_due
  // must not be counted again as upcoming.
  static CalendarDate firstUnpostedAfter(Schedule schedule, CalendarDate nextDue, {required CalendarDate today}) {
    final CalendarDate tomorrow = today.addDays(1);
    return firstOnOrAfter(schedule, nextDue.isAfter(tomorrow) ? nextDue : tomorrow);
  }

  /// Every due date from [first] (itself a due date) up to and including [through].
  static List<CalendarDate> datesFrom(Schedule schedule, CalendarDate first, {required CalendarDate through}) {
    final List<CalendarDate> dates = <CalendarDate>[];
    for (CalendarDate date = first; !date.isAfter(through); date = next(schedule, date)) {
      dates.add(date);
    }
    return List<CalendarDate>.unmodifiable(dates);
  }

  /// An anchor for a monthly rule on [day]: that day in [near]'s month, or in the closest
  /// earlier month long enough to have it, so a rule on the 31st keeps its day.
  static CalendarDate monthlyAnchor(int day, {required CalendarDate near}) {
    int monthIndex = near.year * 12 + near.month - 1;
    while (CalendarDate.daysInMonth(monthIndex ~/ 12, monthIndex % 12 + 1) < day) {
      monthIndex -= 1;
    }
    return CalendarDate(monthIndex ~/ 12, monthIndex % 12 + 1, day);
  }

  static CalendarDate _notBefore(CalendarDate date, CalendarDate candidate, Schedule schedule) =>
      candidate.isBefore(date) ? next(schedule, candidate) : candidate;

  // why: occurrences are anchor + k·period for every integer k, so the distance to the next one
  // is (anchor − date) mod period, which also works for dates before the anchor.
  static CalendarDate _nextInPhase(CalendarDate anchor, CalendarDate date, int period) =>
      date.addDays(date.daysUntil(anchor) % period);

  /// The monthly due date in [month] of [year]; [month] may be 13 to mean January of next year.
  static CalendarDate _monthlyIn(Schedule schedule, int year, int month) {
    final int monthIndex = year * 12 + month - 1;
    final int targetYear = monthIndex ~/ 12;
    final int targetMonth = monthIndex % 12 + 1;
    final int lastDay = CalendarDate.daysInMonth(targetYear, targetMonth);
    final int day = schedule.lastDayOfMonth ? lastDay : _clamp(schedule.anchor.day, lastDay);
    return CalendarDate(targetYear, targetMonth, day);
  }

  static CalendarDate _yearlyIn(Schedule schedule, int year) {
    final int month = schedule.anchor.month;
    return CalendarDate(year, month, _clamp(schedule.anchor.day, CalendarDate.daysInMonth(year, month)));
  }

  static int _clamp(int day, int lastDay) => day < lastDay ? day : lastDay;
}
