import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';

void main() {
  group('TimeWindow (BR-17)', () {
    test('contains its start and not its end', () {
      const TimeWindow window = TimeWindow(startMinute: 585, lengthMinutes: 60);

      expect(window.contains(585), isTrue);
      expect(window.contains(644), isTrue);
      expect(window.contains(645), isFalse);
      expect(window.contains(584), isFalse);
    });

    test('a window across midnight holds both sides (E58)', () {
      const TimeWindow window = TimeWindow(startMinute: 1395, lengthMinutes: 90);

      expect(window.contains(1400), isTrue);
      expect(window.contains(0), isTrue);
      expect(window.contains(44), isTrue);
      expect(window.contains(45), isFalse);
      expect(window.contains(1394), isFalse);
    });

    test('a whole-day window holds every minute', () {
      const TimeWindow window = TimeWindow(startMinute: 15, lengthMinutes: 1440);

      expect(List<int>.generate(1440, (int minute) => minute).every(window.contains), isTrue);
    });

    test('middleMinute wraps past midnight', () {
      expect(const TimeWindow(startMinute: 585, lengthMinutes: 60).middleMinute, 615);
      expect(const TimeWindow(startMinute: 1395, lengthMinutes: 90).middleMinute, 0);
    });

    const List<(String, TimeWindow, int)> hours = <(String, TimeWindow, int)>[
      ('9:45–10:45 is 10', TimeWindow(startMinute: 585, lengthMinutes: 60), 10),
      ('9:45–11:15 is 11, the half hour up', TimeWindow(startMinute: 585, lengthMinutes: 90), 11),
      ('23:15–00:45 is 0', TimeWindow(startMinute: 1395, lengthMinutes: 90), 0),
      ('11:15–12:15 is 12', TimeWindow(startMinute: 675, lengthMinutes: 60), 12),
      ('22:45–00:15 is 0, the half hour up past midnight', TimeWindow(startMinute: 1365, lengthMinutes: 90), 0),
      ('9:00–9:30 is 9, rounding down', TimeWindow(startMinute: 540, lengthMinutes: 30), 9),
    ];
    for (final (String name, TimeWindow window, int hour) in hours) {
      test('aroundHour is the hour nearest the middle; a half hour rounds up: $name', () {
        expect(window.aroundHour, hour);
      });
    }

    test('compares by its start and length', () {
      expect(
        const TimeWindow(startMinute: 585, lengthMinutes: 60),
        const TimeWindow(startMinute: 585, lengthMinutes: 60),
      );
      expect(
        const TimeWindow(startMinute: 585, lengthMinutes: 60),
        isNot(const TimeWindow(startMinute: 585, lengthMinutes: 90)),
      );
    });
  });
}
