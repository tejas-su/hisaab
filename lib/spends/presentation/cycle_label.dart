import 'package:intl/intl.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';

/// The name a cycle goes by in the switcher, the empty state and Ask AI, e.g. "October"
/// (SPEC FR-SP-1, FR-AI-2).
abstract final class CycleLabel {
  static const int _shortestMonthDays = 28;

  /// Names [cycle] in [locale]: the month holding most of its days, with the year when it isn't
  /// [today]'s year; a weekly cycle is named by its dates ("26 Oct – 1 Nov") (DECISIONS D52).
  static String of(PayCycle cycle, {required String locale, required CalendarDate today}) {
    if (cycle.lengthInDays < _shortestMonthDays) {
      final DateFormat dayMonth = DateFormat('d MMM', locale);
      return '${dayMonth.format(_dateTime(cycle.start))} – ${dayMonth.format(_dateTime(cycle.end))}';
    }
    final CalendarDate middle = _middle(cycle);
    final String pattern = middle.year == today.year ? 'MMMM' : 'MMMM y';
    return DateFormat(pattern, locale).format(_dateTime(middle));
  }

  /// Names the span of [cycles] (newest first) in [locale], oldest end first: short month names
  /// for monthly cycles ("Aug", "Oct"), dates for weekly ones ("12 Oct", "1 Nov"). Never a year,
  /// since the span is always recent (FR-AI-2).
  static (String, String) rangeOf(List<PayCycle> cycles, {required String locale}) {
    final PayCycle oldest = cycles.last;
    final PayCycle newest = cycles.first;
    if (newest.lengthInDays < _shortestMonthDays) {
      final DateFormat dayMonth = DateFormat('d MMM', locale);
      return (dayMonth.format(_dateTime(oldest.start)), dayMonth.format(_dateTime(newest.end)));
    }
    final DateFormat month = DateFormat('MMM', locale);
    return (month.format(_dateTime(_middle(oldest))), month.format(_dateTime(_middle(newest))));
  }

  static CalendarDate _middle(PayCycle cycle) => cycle.start.addDays(cycle.lengthInDays ~/ 2);

  static DateTime _dateTime(CalendarDate day) => DateTime(day.year, day.month, day.day);
}
