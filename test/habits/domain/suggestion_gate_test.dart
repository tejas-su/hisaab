import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/suggestion_gate.dart';

const int _chai = 13;

/// Mon 26 Oct 2026, day 0 in these tests.
const CalendarDate _day0 = CalendarDate(2026, 10, 26);

const Option<SuggestionState> _noState = Option<SuggestionState>.none();

SuggestionState _undoOn(CalendarDate day, {Option<SuggestionState> after = _noState}) =>
    SuggestionGate.afterUndo(after, categoryId: _chai, today: day);

GateStatus _statusOn(CalendarDate day, SuggestionState state) =>
    SuggestionGate.statusOf(Option<SuggestionState>.of(state), today: day);

void main() {
  group('SuggestionGate (BR-17 quiet)', () {
    test('no state is open', () {
      expect(SuggestionGate.statusOf(_noState, today: _day0), GateStatus.open);
      expect(_statusOn(_day0, const SuggestionState(categoryId: _chai)), GateStatus.open);
    });

    test('after an Undo: quiet today, open tomorrow (E63)', () {
      final SuggestionState state = _undoOn(_day0);

      expect(state, const SuggestionState(categoryId: _chai, quietOn: Option<CalendarDate>.of(_day0)));
      expect(_statusOn(_day0, state), GateStatus.quietToday);
      expect(_statusOn(_day0.addDays(1), state), GateStatus.open);
    });

    test('a second Undo 14 days later rests for 30 days', () {
      final CalendarDate day14 = _day0.addDays(14);

      final SuggestionState state = _undoOn(day14, after: Option<SuggestionState>.of(_undoOn(_day0)));

      expect(
        state,
        SuggestionState(
          categoryId: _chai,
          quietOn: Option<CalendarDate>.of(day14),
          restUntil: Option<CalendarDate>.of(day14.addDays(30)),
        ),
      );
    });

    test('15 days later only quiets', () {
      final CalendarDate day15 = _day0.addDays(15);

      final SuggestionState state = _undoOn(day15, after: Option<SuggestionState>.of(_undoOn(_day0)));

      expect(state, SuggestionState(categoryId: _chai, quietOn: Option<CalendarDate>.of(day15)));
      expect(_statusOn(day15.addDays(1), state), GateStatus.open);
    });

    test('a second Undo on the same day rests too', () {
      final SuggestionState state = _undoOn(_day0, after: Option<SuggestionState>.of(_undoOn(_day0)));

      expect(state.restUntil, Option<CalendarDate>.of(_day0.addDays(30)));
    });

    test('an earlier Undo dated after today, the clock set back, only quiets', () {
      final SuggestionState state = _undoOn(_day0, after: Option<SuggestionState>.of(_undoOn(_day0.addDays(3))));

      expect(state, const SuggestionState(categoryId: _chai, quietOn: Option<CalendarDate>.of(_day0)));
    });

    test('resting on day 30, open on day 31', () {
      final SuggestionState state = _undoOn(_day0, after: Option<SuggestionState>.of(_undoOn(_day0)));

      expect(_statusOn(_day0, state), GateStatus.resting);
      expect(_statusOn(_day0.addDays(1), state), GateStatus.resting);
      expect(_statusOn(_day0.addDays(30), state), GateStatus.resting);
      expect(_statusOn(_day0.addDays(31), state), GateStatus.open);
    });

    test('Forget rests through day 30 and is open on day 31', () {
      final SuggestionState state =
          SuggestionGate.afterForget(_noState, categoryId: _chai, now: DateTime(2026, 10, 26, 21, 15));

      expect(_statusOn(_day0, state), GateStatus.resting);
      expect(_statusOn(_day0.addDays(30), state), GateStatus.resting);
      expect(_statusOn(_day0.addDays(31), state), GateStatus.open);
    });

    test('an Undo after a rest ended counts as a first', () {
      final SuggestionState rested = _undoOn(_day0, after: Option<SuggestionState>.of(_undoOn(_day0)));
      final CalendarDate day31 = _day0.addDays(31);

      final SuggestionState state = _undoOn(day31, after: Option<SuggestionState>.of(rested));

      expect(state.quietOn, Option<CalendarDate>.of(day31));
      expect(state.restUntil, Option<CalendarDate>.of(_day0.addDays(30)), reason: 'the old rest is not renewed');
      expect(_statusOn(day31, state), GateStatus.quietToday);
      expect(_statusOn(day31.addDays(1), state), GateStatus.open);
    });

    test('Forget sets forgottenAt to now and rests 30 days, keeping quietOn', () {
      final DateTime now = DateTime(2026, 10, 28, 21, 15);

      final SuggestionState state = SuggestionGate.afterForget(
        Option<SuggestionState>.of(_undoOn(_day0)),
        categoryId: _chai,
        now: now,
      );

      expect(
        state,
        SuggestionState(
          categoryId: _chai,
          quietOn: const Option<CalendarDate>.of(_day0),
          restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 27)),
          forgottenAt: Option<DateTime>.of(now),
        ),
      );
    });

    test('Forget with no earlier state has no quiet day', () {
      final DateTime now = DateTime(2026, 10, 26, 21, 15);

      final SuggestionState state = SuggestionGate.afterForget(_noState, categoryId: _chai, now: now);

      expect(
        state,
        SuggestionState(
          categoryId: _chai,
          restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
          forgottenAt: Option<DateTime>.of(now),
        ),
      );
    });

    test('an Undo keeps forgottenAt', () {
      final SuggestionState forgotten =
          SuggestionGate.afterForget(_noState, categoryId: _chai, now: DateTime(2026, 9, 1, 8));

      final SuggestionState state = _undoOn(_day0, after: Option<SuggestionState>.of(forgotten));

      expect(state.forgottenAt, Option<DateTime>.of(DateTime(2026, 9, 1, 8)));
      expect(state.restUntil, const Option<CalendarDate>.of(CalendarDate(2026, 10, 1)));
    });

    test('a rest across New Year and across 29 February', () {
      const CalendarDate december = CalendarDate(2027, 12, 15);

      final SuggestionState overNewYear = _undoOn(december, after: Option<SuggestionState>.of(_undoOn(december)));
      final SuggestionState overLeapDay =
          SuggestionGate.afterForget(_noState, categoryId: _chai, now: DateTime(2028, 2, 10, 9));

      expect(overNewYear.restUntil, const Option<CalendarDate>.of(CalendarDate(2028, 1, 14)));
      expect(_statusOn(const CalendarDate(2028, 1, 14), overNewYear), GateStatus.resting);
      expect(_statusOn(const CalendarDate(2028, 1, 15), overNewYear), GateStatus.open);
      expect(overLeapDay.restUntil, const Option<CalendarDate>.of(CalendarDate(2028, 3, 11)));
      expect(_statusOn(const CalendarDate(2028, 3, 11), overLeapDay), GateStatus.resting);
      expect(_statusOn(const CalendarDate(2028, 3, 12), overLeapDay), GateStatus.open);
    });
  });
}
