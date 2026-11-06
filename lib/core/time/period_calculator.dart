import 'calendar_date.dart';
import 'month_start.dart';
import 'pay_cycle.dart';
import 'pay_rule.dart';
import 'pay_switch.dart';

/// Works out which pay cycle a day belongs to (SPEC BR-1); the only home of cycle maths.
final class PeriodCalculator {
  const PeriodCalculator();

  /// Returns the cycle containing [today] for [rule], or the calendar month when
  /// [monthStart] is [MonthStart.firstOfMonth].
  ///
  /// [switches] are the earlier pay rules, oldest first (BR-1a). The cycle a change falls in keeps
  /// its start and ends the day before the first new payday after the change, so pay already
  /// received stays in its cycle; cycles before it keep the old rule.
  PayCycle cycleFor({
    required CalendarDate today,
    required PayRule rule,
    required MonthStart monthStart,
    List<PaySwitch> switches = const <PaySwitch>[],
  }) {
    if (monthStart == MonthStart.firstOfMonth) {
      return _calendarMonth(today);
    }
    return _withSwitches(today, rule, switches);
  }

  PayCycle _withSwitches(CalendarDate today, PayRule rule, List<PaySwitch> switches) {
    if (switches.isEmpty) {
      return _plain(today, rule);
    }
    final PaySwitch last = switches.last;
    final List<PaySwitch> earlier = switches.sublist(0, switches.length - 1);
    final CalendarDate bridgeStart = _withSwitches(last.on, last.from, earlier).start;
    final CalendarDate bridgeEnd = _plain(last.on, rule).end;
    if (today.isBefore(bridgeStart)) {
      return _withSwitches(today, last.from, earlier);
    }
    return today.isAfter(bridgeEnd) ? _plain(today, rule) : PayCycle(start: bridgeStart, end: bridgeEnd);
  }

  PayCycle _plain(CalendarDate today, PayRule rule) {
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
