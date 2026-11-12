import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';

void main() {
  group('DayType.of (BR-17)', () {
    const List<(String, CalendarDate, DayType)> days = <(String, CalendarDate, DayType)>[
      ('Monday', CalendarDate(2026, 10, 26), DayType.weekday),
      ('Tuesday', CalendarDate(2026, 10, 27), DayType.weekday),
      ('Wednesday', CalendarDate(2026, 10, 28), DayType.weekday),
      ('Thursday', CalendarDate(2026, 10, 29), DayType.weekday),
      ('Friday', CalendarDate(2026, 10, 30), DayType.weekday),
      ('Saturday', CalendarDate(2026, 10, 31), DayType.weekend),
      ('Sunday', CalendarDate(2026, 11, 1), DayType.weekend),
    ];
    for (final (String name, CalendarDate date, DayType expected) in days) {
      test('Monday to Friday are weekdays, Saturday and Sunday the weekend: $name', () {
        expect(DayType.of(date), expected);
      });
    }
  });
}
