import 'package:intl/intl.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';

/// The name a cycle goes by in the switcher and the empty state, e.g. "October" (SPEC FR-SP-1).
abstract final class CycleLabel {
  static const int _shortestMonthDays = 28;

  /// Names [cycle] in [locale]: the month holding most of its days, with the year when it isn't
  /// [today]'s year; a weekly cycle is named by its dates ("26 Oct – 1 Nov") (DECISIONS D52).
  static String of(PayCycle cycle, {required String locale, required CalendarDate today}) {
    if (cycle.lengthInDays < _shortestMonthDays) {
      final DateFormat dayMonth = DateFormat('d MMM', locale);
      return '${dayMonth.format(_dateTime(cycle.start))} – ${dayMonth.format(_dateTime(cycle.end))}';
    }
    final CalendarDate middle = cycle.start.addDays(cycle.lengthInDays ~/ 2);
    final String pattern = middle.year == today.year ? 'MMMM' : 'MMMM y';
    return DateFormat(pattern, locale).format(_dateTime(middle));
  }

  static DateTime _dateTime(CalendarDate day) => DateTime(day.year, day.month, day.day);
}
