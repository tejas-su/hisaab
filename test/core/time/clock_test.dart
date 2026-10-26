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

    group('untilTomorrow (BR-8 midnight re-run)', () {
      test('is the time left until the next local midnight', () {
        final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 22, 30));
        expect(clock.untilTomorrow(), const Duration(hours: 1, minutes: 30));
      });

      test('is a whole day exactly at midnight', () {
        final FakeClock clock = FakeClock(DateTime(2026, 10, 26));
        expect(clock.untilTomorrow(), const Duration(days: 1));
      });

      test('crosses the year end', () {
        final FakeClock clock = FakeClock(DateTime(2026, 12, 31, 23, 59, 59));
        expect(clock.untilTomorrow(), const Duration(seconds: 1));
      });
    });

    test('SystemClock reports the device time', () {
      final DateTime before = DateTime.now();
      final DateTime reported = const SystemClock().now();
      expect(reported.isBefore(before), isFalse);
    });
  });
}
