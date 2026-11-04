import 'calendar_date.dart';
import 'month_start.dart';
import 'pay_cycle.dart';
import 'pay_rule.dart';

/// Works out which pay cycle a day belongs to (SPEC BR-1); the only home of cycle maths.
final class PeriodCalculator {
  const PeriodCalculator();

  /// Returns the cycle containing [today] for [rule], or the calendar month when
  /// [monthStart] is [MonthStart.firstOfMonth].
  PayCycle cycleFor({required CalendarDate today, required PayRule rule, required MonthStart monthStart}) {
    if (monthStart == MonthStart.firstOfMonth) {
      return _calendarMonth(today);
    }
    return switch (rule) {
      MonthlyOnDay(:final int day) => _monthly(today, (int year, int month) => _clampedDay(year, month, day)),
      LastDayOfMonth() => _monthly(today, _lastDay),
      WeeklyOn(:final int weekday) => _weekly(today, weekday),
      IrregularIncome() => _calendarMonth(today),
    };
  }

  /// Whether cycles for [rule] and [monthStart] follow the calendar month, so they end at month end
  /// rather than the day before a payday (BR-1; DECISIONS D116).
  bool endsAtMonthEnd({required PayRule rule, required MonthStart monthStart}) =>
      monthStart == MonthStart.firstOfMonth || rule is IrregularIncome;

  PayCycle _monthly(CalendarDate today, CalendarDate Function(int year, int month) paydayIn) {
    final CalendarDate thisMonth = paydayIn(today.year, today.month);
    final CalendarDate start = thisMonth.isAfter(today) ? _shiftMonth(today, -1, paydayIn) : thisMonth;
    final CalendarDate nextStart = _shiftMonth(start, 1, paydayIn);
    return PayCycle(start: start, end: nextStart.addDays(-1));
  }

  CalendarDate _shiftMonth(
    CalendarDate from,
    int months,
    CalendarDate Function(int year, int month) paydayIn,
  ) {
    final int monthIndex = from.year * 12 + (from.month - 1) + months;
    return paydayIn(monthIndex ~/ 12, monthIndex % 12 + 1);
  }

  PayCycle _weekly(CalendarDate today, int weekday) {
    final CalendarDate start = today.addDays(-((today.weekday - weekday) % 7));
    return PayCycle(start: start, end: start.addDays(6));
  }

  PayCycle _calendarMonth(CalendarDate today) =>
      PayCycle(start: CalendarDate(today.year, today.month, 1), end: _lastDay(today.year, today.month));

  CalendarDate _clampedDay(int year, int month, int day) {
    final int lastDay = CalendarDate.daysInMonth(year, month);
    return CalendarDate(year, month, day < lastDay ? day : lastDay);
  }

  CalendarDate _lastDay(int year, int month) => CalendarDate(year, month, CalendarDate.daysInMonth(year, month));
}
