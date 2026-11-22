import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/nudge_state.dart';
import 'package:hisaab/habits/domain/nudge_settler.dart';

/// The nudge of BR-22.5's examples: 15:30 on Wed 4 Nov 2026.
final DateTime _armed = DateTime(2026, 11, 4, 15, 30);

NudgeState _state({Option<DateTime>? armedFor, int streak = 0, Option<CalendarDate> rest = const Option<CalendarDate>.none()}) =>
    NudgeState(categoryId: 3, armedFor: armedFor ?? Option<DateTime>.of(_armed), ignoredStreak: streak, restUntil: rest);

NudgeState _settled(NudgeState state, DateTime now, List<DateTime> loggedAt) =>
    NudgeSettler.settle(state, now: now, loggedAt: loggedAt);

void main() {
  group('NudgeSettler.settle (BR-22.5)', () {
    final DateTime afterWindow = _armed.add(const Duration(minutes: 61));

    test('leaves a state with no armedFor unchanged', () {
      final NudgeState state = _state(armedFor: const Option<DateTime>.none(), streak: 2);
      expect(_settled(state, afterWindow, <DateTime>[]), state);
    });

    test('gives no verdict while armedFor is still in the future', () {
      final NudgeState state = _state();
      expect(_settled(state, _armed.subtract(const Duration(minutes: 5)), <DateTime>[]), state);
    });

    test('gives no verdict inside the 60 minute window', () {
      final NudgeState state = _state();
      expect(_settled(state, _armed.add(const Duration(minutes: 30)), <DateTime>[]), state);
    });

    test('gives no verdict at exactly +60 minutes, so a late entry can still count', () {
      final NudgeState state = _state();
      expect(_settled(state, _armed.add(const Duration(minutes: 60)), <DateTime>[]), state);
    });

    test('settles worked for an entry at armedFor', () {
      final NudgeState result = _settled(_state(streak: 2), afterWindow, <DateTime>[_armed]);
      expect(result.armedFor, const Option<DateTime>.none());
      expect(result.ignoredStreak, 0);
    });

    test('settles worked for an entry at exactly +60 minutes (16:30)', () {
      final NudgeState result =
          _settled(_state(streak: 2), afterWindow, <DateTime>[DateTime(2026, 11, 4, 16, 30)]);
      expect(result.ignoredStreak, 0);
      expect(result.armedFor, const Option<DateTime>.none());
    });

    test('settles ignored for an entry at 16:31, one minute past the window', () {
      final NudgeState result =
          _settled(_state(), DateTime(2026, 11, 4, 17), <DateTime>[DateTime(2026, 11, 4, 16, 31)]);
      expect(result.ignoredStreak, 1);
    });

    test('settles ignored at +60 minutes and 1 second with no entry', () {
      final NudgeState result = _settled(_state(), _armed.add(const Duration(minutes: 60, seconds: 1)), <DateTime>[]);
      expect(result.armedFor, const Option<DateTime>.none());
      expect(result.ignoredStreak, 1);
    });

    test('cancels, with no verdict, for an entry before armedFor (15:20)', () {
      final NudgeState result =
          _settled(_state(streak: 2), afterWindow, <DateTime>[DateTime(2026, 11, 4, 15, 20)]);
      expect(result.armedFor, const Option<DateTime>.none());
      expect(result.ignoredStreak, 2);
      expect(result.restUntil, const Option<CalendarDate>.none());
    });

    test('cancels when entries fall both before and inside the window', () {
      final NudgeState result = _settled(
        _state(streak: 2),
        afterWindow,
        <DateTime>[DateTime(2026, 11, 4, 15, 20), DateTime(2026, 11, 4, 15, 45)],
      );
      expect(result.ignoredStreak, 2);
      expect(result.armedFor, const Option<DateTime>.none());
    });

    test('rests through day 30 after the armed day on the third ignored in a row and resets the streak', () {
      final NudgeState result = _settled(_state(streak: 2), afterWindow, <DateTime>[]);
      expect(result.restUntil, Option<CalendarDate>.of(const CalendarDate(2026, 12, 4)));
      expect(result.ignoredStreak, 0);
      expect(result.armedFor, const Option<DateTime>.none());
    });

    test('rest crosses the year: third ignored armed 15 Dec 2026 rests through 14 Jan 2027 (BR-22.5)', () {
      final DateTime armed = DateTime(2026, 12, 15, 15, 30);
      final NudgeState third = _state(armedFor: Option<DateTime>.of(armed), streak: 2);
      final NudgeState result = _settled(third, armed.add(const Duration(hours: 2)), <DateTime>[]);
      expect(result.restUntil, Option<CalendarDate>.of(const CalendarDate(2027, 1, 14)));
    });

    test('rest counts the leap day: third ignored armed 31 Jan 2028 rests through 1 Mar 2028 (BR-22.5)', () {
      final DateTime armed = DateTime(2028, 1, 31, 15, 30);
      final NudgeState third = _state(armedFor: Option<DateTime>.of(armed), streak: 2);
      final NudgeState result = _settled(third, armed.add(const Duration(hours: 2)), <DateTime>[]);
      expect(result.restUntil, Option<CalendarDate>.of(const CalendarDate(2028, 3, 1)));
    });

    test('counts two ignored in a row without a rest', () {
      final NudgeState result = _settled(_state(streak: 1), afterWindow, <DateTime>[]);
      expect(result.ignoredStreak, 2);
      expect(result.restUntil, const Option<CalendarDate>.none());
    });

    test('keeps a restUntil already set when a later verdict triggers no new rest', () {
      const Option<CalendarDate> rest = Option<CalendarDate>.of(CalendarDate(2026, 10, 1));
      final NudgeState result = _settled(_state(streak: 1, rest: rest), afterWindow, <DateTime>[]);
      expect(result.restUntil, rest);
    });

    test('settles a nudge armed days ago, once only', () {
      final DateTime later = _armed.add(const Duration(days: 3));
      final NudgeState once = _settled(_state(streak: 0), later, <DateTime>[]);
      expect(once.ignoredStreak, 1);
      expect(_settled(once, later, <DateTime>[]), once);
    });

    test('settling a worked state again changes nothing', () {
      final NudgeState once = _settled(_state(streak: 2), afterWindow, <DateTime>[_armed]);
      expect(_settled(once, afterWindow, <DateTime>[_armed]), once);
    });
  });
}
