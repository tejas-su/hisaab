import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes/fake_clock.dart';

void main() {
  group('Clock', () {
    test('today drops the time of day', () {
      final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 23, 59, 59));
      expect(clock.today(), const CalendarDate(2026, 10, 26));
    });

    test('today changes after midnight', () {
      final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 23, 59))..advance(const Duration(minutes: 2));
      expect(clock.today(), const CalendarDate(2026, 10, 27));
    });

    test('SystemClock reports the device time', () {
      final DateTime before = DateTime.now();
      final DateTime reported = const SystemClock().now();
      expect(reported.isBefore(before), isFalse);
    });
  });
}
