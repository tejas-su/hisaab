import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/time_profile.dart';

/// 48 unsmoothed slot sums, zero except for [busy] (slot → weight).
List<double> _slots(Map<int, double> busy) => List<double>.generate(48, (int slot) => busy[slot] ?? 0);

void main() {
  group('TimeProfile (BR-17)', () {
    test('slotOf and minuteOf read the wall clock', () {
      expect(TimeProfile.slotOf(DateTime(2026, 10, 26, 10, 5)), 20);
      expect(TimeProfile.minuteOf(DateTime(2026, 10, 26, 10, 5)), 605);
      expect(TimeProfile.slotOf(DateTime(2026, 10, 26, 10, 30)), 21);
      expect(TimeProfile.slotOf(DateTime(2026, 10, 26, 23, 59)), 47);
      expect(TimeProfile.slotOf(DateTime(2026, 10, 26)), 0);
      expect(TimeProfile.minuteOf(DateTime(2026, 10, 26)), 0);
    });

    test('slotOf and minuteOf read the wall clock: a UTC and a local time with the same fields agree (E62)', () {
      final DateTime local = DateTime(2026, 10, 26, 10, 5);
      final DateTime utc = DateTime.utc(2026, 10, 26, 10, 5);

      expect(TimeProfile.slotOf(utc), TimeProfile.slotOf(local));
      expect(TimeProfile.minuteOf(utc), TimeProfile.minuteOf(local));
    });

    test('weightOf halves every 14 days', () {
      expect(TimeProfile.weightOf(0), 1.0);
      expect(TimeProfile.weightOf(14), 0.5);
      expect(TimeProfile.weightOf(28), 0.25);
      expect(TimeProfile.weightOf(7), closeTo(0.7071, 1e-4));
    });

    test('one busy slot gives a 60-minute window', () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{20: 1})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 585, lengthMinutes: 60)),
      );
    });

    test('two busy neighbours give a 90-minute window', () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{20: 1, 21: 1})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 585, lengthMinutes: 90)),
      );
    });

    test('the run stops at a slot at exactly half the peak', () {
      final Option<TimeWindow> window = TimeProfile.windowOf(_slots(<int, double>{20: 1}));

      expect(
        window.map((TimeWindow w) => w.contains(9 * 60 + 44)),
        const Option<bool>.of(false),
        reason: 'slot 19 smooths to exactly half the peak',
      );
      expect(
        window.map((TimeWindow w) => w.contains(10 * 60 + 45)),
        const Option<bool>.of(false),
        reason: 'slot 21 smooths to exactly half the peak',
      );
    });

    test('a slot just above half the peak joins the run', () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{19: 0.01, 20: 1})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 555, lengthMinutes: 90)),
      );
    });

    test('a run across midnight wraps', () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{47: 1, 0: 1})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 1395, lengthMinutes: 90)),
      );
    });

    test('a window whose run starts in the first slot begins before midnight', () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{0: 1})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 1425, lengthMinutes: 60)),
      );
    });

    test("two separate peaks: the window is the higher one's run", () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{20: 4, 32: 3})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 585, lengthMinutes: 60)),
      );
    });

    test('two equal peaks: the earlier slot wins', () {
      expect(
        TimeProfile.windowOf(_slots(<int, double>{20: 2, 32: 2})),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 585, lengthMinutes: 60)),
      );
    });

    test('an even spread has no window', () {
      expect(TimeProfile.windowOf(List<double>.filled(48, 1)), const Option<TimeWindow>.none());
    });

    test('a run of 47 slots is the whole day, never more', () {
      final List<double> weights = List<double>.generate(48, (int slot) => slot == 0 ? 0 : 1);

      expect(
        TimeProfile.windowOf(weights),
        const Option<TimeWindow>.of(TimeWindow(startMinute: 15, lengthMinutes: 1440)),
      );
    });

    test('no weight, no window', () {
      expect(TimeProfile.windowOf(List<double>.filled(48, 0)), const Option<TimeWindow>.none());
    });
  });
}
