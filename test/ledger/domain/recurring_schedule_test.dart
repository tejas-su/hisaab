import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';
import 'package:expense_tracker/ledger/domain/recurring_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarDate _d(int year, int month, int day) => CalendarDate(year, month, day);

void main() {
  group('RecurringSchedule.next', () {
    const Schedule on31st = Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 8, 31));

    final List<(String, Schedule, CalendarDate, CalendarDate)> cases = <(String, Schedule, CalendarDate, CalendarDate)>[
      ('monthly on the 31st clamps to 30 Nov', on31st, _d(2026, 10, 31), _d(2026, 11, 30)),
      ('E1: monthly on the 31st clamps to 28 Feb 2027', on31st, _d(2027, 1, 31), _d(2027, 2, 28)),
      ('monthly returns to the 31st after a short month', on31st, _d(2027, 2, 28), _d(2027, 3, 31)),
      ('E1: leap year clamps to 29 Feb 2028', on31st, _d(2028, 1, 31), _d(2028, 2, 29)),
      ('E3: monthly crosses the year', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 25)),
          _d(2026, 12, 25), _d(2027, 1, 25)),
      ('last day of month', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 31), lastDayOfMonth: true),
          _d(2027, 2, 28), _d(2027, 3, 31)),
      ('weekly adds 7 days', const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2026, 10, 30), _d(2026, 11, 6)),
      ('every 2 weeks adds 14 days', const Schedule(frequency: Frequency.biweekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2026, 12, 25), _d(2027, 1, 8)),
      ('yearly on 29 Feb clamps in common years', const Schedule(frequency: Frequency.yearly, anchor: CalendarDate(2028, 2, 29)),
          _d(2028, 2, 29), _d(2029, 2, 28)),
      ('yearly returns to 29 Feb in leap years', const Schedule(frequency: Frequency.yearly, anchor: CalendarDate(2028, 2, 29)),
          _d(2031, 2, 28), _d(2032, 2, 29)),
    ];
    for (final (String name, Schedule schedule, CalendarDate from, CalendarDate expected) in cases) {
      test(name, () => expect(RecurringSchedule.next(schedule, from), expected));
    }
  });

  group('RecurringSchedule.previous', () {
    const Schedule on31st = Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 8, 31));

    final List<(String, Schedule, CalendarDate, CalendarDate)> cases = <(String, Schedule, CalendarDate, CalendarDate)>[
      ('monthly on the 31st clamps to 30 Nov', on31st, _d(2026, 12, 31), _d(2026, 11, 30)),
      ('monthly on the 31st clamps to 28 Feb', on31st, _d(2027, 3, 31), _d(2027, 2, 28)),
      ('monthly returns to the 31st before a short month', on31st, _d(2026, 11, 30), _d(2026, 10, 31)),
      ('monthly crosses the year backwards', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 25)),
          _d(2027, 1, 25), _d(2026, 12, 25)),
      ('weekly takes 7 days', const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2026, 11, 6), _d(2026, 10, 30)),
      ('every 2 weeks takes 14 days', const Schedule(frequency: Frequency.biweekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2027, 1, 8), _d(2026, 12, 25)),
      ('yearly on 29 Feb clamps in the common year before', const Schedule(frequency: Frequency.yearly, anchor: CalendarDate(2028, 2, 29)),
          _d(2032, 2, 29), _d(2031, 2, 28)),
    ];
    for (final (String name, Schedule schedule, CalendarDate from, CalendarDate expected) in cases) {
      test(name, () => expect(RecurringSchedule.previous(schedule, from), expected));
    }
  });

  group('RecurringSchedule.firstOnOrAfter', () {
    final List<(String, Schedule, CalendarDate, CalendarDate)> cases = <(String, Schedule, CalendarDate, CalendarDate)>[
      ('monthly, later this month', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 5)),
          _d(2026, 10, 4), _d(2026, 10, 5)),
      ('monthly, the same day', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 5)),
          _d(2026, 10, 5), _d(2026, 10, 5)),
      ('monthly, already passed: next month', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 3)),
          _d(2026, 10, 4), _d(2026, 11, 3)),
      ('monthly 31st in a 30-day month', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 8, 31)),
          _d(2026, 9, 10), _d(2026, 9, 30)),
      ('last day of month', const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 31), lastDayOfMonth: true),
          _d(2027, 2, 1), _d(2027, 2, 28)),
      ('weekly, later this week', const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2026, 10, 26), _d(2026, 10, 30)),
      ('weekly, the same weekday', const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2026, 10, 30), _d(2026, 10, 30)),
      ('every 2 weeks keeps its phase', const Schedule(frequency: Frequency.biweekly, anchor: CalendarDate(2026, 10, 2)),
          _d(2026, 10, 17), _d(2026, 10, 30)),
      ('every 2 weeks before the anchor', const Schedule(frequency: Frequency.biweekly, anchor: CalendarDate(2026, 10, 30)),
          _d(2026, 10, 10), _d(2026, 10, 16)),
      ('yearly, later this year', const Schedule(frequency: Frequency.yearly, anchor: CalendarDate(2020, 12, 1)),
          _d(2026, 10, 26), _d(2026, 12, 1)),
      ('yearly, already passed', const Schedule(frequency: Frequency.yearly, anchor: CalendarDate(2020, 3, 1)),
          _d(2026, 10, 26), _d(2027, 3, 1)),
    ];
    for (final (String name, Schedule schedule, CalendarDate from, CalendarDate expected) in cases) {
      test(name, () => expect(RecurringSchedule.firstOnOrAfter(schedule, from), expected));
    }
  });

  group('RecurringSchedule.datesFrom', () {
    const Schedule weekly = Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 9, 18));

    test('E7: six weeks away lists all six occurrences, each with its own date', () {
      expect(RecurringSchedule.datesFrom(weekly, _d(2026, 9, 18), through: _d(2026, 10, 26)), <CalendarDate>[
        _d(2026, 9, 18),
        _d(2026, 9, 25),
        _d(2026, 10, 2),
        _d(2026, 10, 9),
        _d(2026, 10, 16),
        _d(2026, 10, 23),
      ]);
    });

    test('includes an occurrence on the last day', () {
      expect(RecurringSchedule.datesFrom(weekly, _d(2026, 10, 23), through: _d(2026, 10, 23)), <CalendarDate>[_d(2026, 10, 23)]);
    });

    test('E9: nothing when the first date is after the end', () {
      expect(RecurringSchedule.datesFrom(weekly, _d(2026, 10, 30), through: _d(2026, 10, 26)), isEmpty);
    });
  });

  group('RecurringSchedule.monthlyAnchor', () {
    test('uses the day in the given month when it exists', () {
      expect(RecurringSchedule.monthlyAnchor(4, near: _d(2026, 10, 26)), _d(2026, 10, 4));
      expect(RecurringSchedule.monthlyAnchor(31, near: _d(2026, 10, 26)), _d(2026, 10, 31));
    });

    test('steps back to a month that has the day, so the 31st is not lost', () {
      expect(RecurringSchedule.monthlyAnchor(31, near: _d(2026, 11, 5)), _d(2026, 10, 31));
      expect(RecurringSchedule.monthlyAnchor(30, near: _d(2027, 2, 10)), _d(2027, 1, 30));
      expect(RecurringSchedule.monthlyAnchor(31, near: _d(2027, 1, 1)), _d(2027, 1, 31));
    });
  });
}
