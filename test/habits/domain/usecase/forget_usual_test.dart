import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/forgotten_usual.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/usecase/forget_usual.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';

final DateTime _now = DateTime(2026, 10, 26, 10, 30);
const Option<CalendarDate> _restUntil = Option<CalendarDate>.of(CalendarDate(2026, 11, 25));

void main() {
  late FakeSuggestionStateRepository states;
  late FakeClock clock;
  late ForgetUsual forget;

  setUp(() {
    states = FakeSuggestionStateRepository();
    clock = FakeClock(_now);
    forget = ForgetUsual(states: states, clock: clock);
  });

  group('ForgetUsual', () {
    test('stores forgottenAt = now and a 30-day rest, and returns none as the previous state', () async {
      final Either<Failure, ForgottenUsual> result = await forget(chai.id).run();

      expect(
        result,
        Either<Failure, ForgottenUsual>.right(
          ForgottenUsual(categoryId: chai.id, previous: const Option<SuggestionState>.none()),
        ),
      );
      expect(
        states.states,
        <int, SuggestionState>{
          chai.id: SuggestionState(categoryId: chai.id, restUntil: _restUntil, forgottenAt: Option<DateTime>.of(_now)),
        },
      );
    });

    test('returns the state it replaced', () async {
      final SuggestionState resting = SuggestionState(
        categoryId: chai.id,
        quietOn: const Option<CalendarDate>.of(CalendarDate(2026, 10, 20)),
        restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 19)),
      );
      states.states[chai.id] = resting;

      final Either<Failure, ForgottenUsual> result = await forget(chai.id).run();

      expect(
        result,
        Either<Failure, ForgottenUsual>.right(
          ForgottenUsual(categoryId: chai.id, previous: Option<SuggestionState>.of(resting)),
        ),
      );
      expect(
        states.states[chai.id],
        SuggestionState(
          categoryId: chai.id,
          quietOn: resting.quietOn,
          restUntil: _restUntil,
          forgottenAt: Option<DateTime>.of(_now),
        ),
      );
    });

    test('a rest that starts on 31 December ends on 30 January', () async {
      clock.current = DateTime(2027, 12, 31, 23, 59);

      await forget(chai.id).run();

      expect(states.states[chai.id]?.restUntil, const Option<CalendarDate>.of(CalendarDate(2028, 1, 30)));
    });

    test('another category\'s state is left alone', () async {
      const SuggestionState foodState = SuggestionState(categoryId: 1);
      states.states[1] = foodState;

      await forget(chai.id).run();

      expect(states.states[1], foodState);
    });

    test('a failed read is returned and stores nothing', () async {
      states.failure = DatabaseFailure('read');

      final Either<Failure, ForgottenUsual> result = await forget(chai.id).run();

      expect(result.getLeft().toNullable(), states.failure);
      expect(states.states, isEmpty);
    });

    test('a failed write is returned', () async {
      states.writeFailure = DatabaseFailure('write');

      final Either<Failure, ForgottenUsual> result = await forget(chai.id).run();

      expect(result.getLeft().toNullable(), states.writeFailure);
      expect(states.states, isEmpty);
    });
  });
}
