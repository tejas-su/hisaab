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

  group('CycleLabel.rangeOf (FR-AI-2)', () {
    PayCycle cycle(CalendarDate start, CalendarDate end) => PayCycle(start: start, end: end);
    final List<(String, List<PayCycle>, (String, String))> cases = <(String, List<PayCycle>, (String, String))>[
      (
        'three monthly cycles, payday on the 4th',
        <PayCycle>[
          cycle(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 3)),
          cycle(const CalendarDate(2026, 9, 4), const CalendarDate(2026, 10, 3)),
          cycle(const CalendarDate(2026, 8, 4), const CalendarDate(2026, 9, 3)),
        ],
        ('Aug', 'Oct'),
      ),
      (
        'monthly cycles across the year, with no year',
        <PayCycle>[
          cycle(const CalendarDate(2027, 1, 1), const CalendarDate(2027, 1, 31)),
          cycle(const CalendarDate(2026, 12, 1), const CalendarDate(2026, 12, 31)),
          cycle(const CalendarDate(2026, 11, 1), const CalendarDate(2026, 11, 30)),
        ],
        ('Nov', 'Jan'),
      ),
      (
        'three weekly cycles: oldest start to newest end',
        <PayCycle>[
          cycle(const CalendarDate(2026, 10, 26), const CalendarDate(2026, 11, 1)),
          cycle(const CalendarDate(2026, 10, 19), const CalendarDate(2026, 10, 25)),
          cycle(const CalendarDate(2026, 10, 12), const CalendarDate(2026, 10, 18)),
        ],
        ('12 Oct', '1 Nov'),
      ),
      (
        'weekly cycles across the year',
        <PayCycle>[
          cycle(const CalendarDate(2027, 1, 4), const CalendarDate(2027, 1, 10)),
          cycle(const CalendarDate(2026, 12, 28), const CalendarDate(2027, 1, 3)),
          cycle(const CalendarDate(2026, 12, 21), const CalendarDate(2026, 12, 27)),
        ],
        ('21 Dec', '10 Jan'),
      ),
    ];
    for (final (String name, List<PayCycle> cycles, (String, String) range) in cases) {
      test('$name: "${range.$1} – ${range.$2}"', () => expect(CycleLabel.rangeOf(cycles, locale: 'en_IN'), range));
    }
  });
}
