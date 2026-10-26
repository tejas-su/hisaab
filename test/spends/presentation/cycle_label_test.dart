import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/spends/presentation/cycle_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);

String _label(CalendarDate start, CalendarDate end) => CycleLabel.of(PayCycle(start: start, end: end), locale: 'en_IN', today: _today);

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  group('CycleLabel.of (FR-SP-1)', () {
    final List<(String, CalendarDate, CalendarDate, String)> cases = <(String, CalendarDate, CalendarDate, String)>[
      ('payday on the 4th', const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 3), 'October'),
      ('a calendar month', const CalendarDate(2026, 10, 1), const CalendarDate(2026, 10, 31), 'October'),
      ('payday on the last day', const CalendarDate(2026, 10, 31), const CalendarDate(2026, 11, 29), 'November'),
      ('payday on the 25th, across the year (E3)', const CalendarDate(2026, 12, 25), const CalendarDate(2027, 1, 24), 'January 2027'),
      ('an earlier year', const CalendarDate(2025, 10, 4), const CalendarDate(2025, 11, 3), 'October 2025'),
      ('February in a leap year', const CalendarDate(2028, 2, 1), const CalendarDate(2028, 2, 29), 'February 2028'),
      ('a weekly cycle', const CalendarDate(2026, 10, 26), const CalendarDate(2026, 11, 1), '26 Oct – 1 Nov'),
    ];
    for (final (String name, CalendarDate start, CalendarDate end, String label) in cases) {
      test('$name: "$label"', () => expect(_label(start, end), label));
    }
  });
}
