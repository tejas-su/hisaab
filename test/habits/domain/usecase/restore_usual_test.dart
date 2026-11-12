import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/forgotten_usual.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/usecase/forget_usual.dart';
import 'package:hisaab/habits/domain/usecase/restore_usual.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';

final SuggestionState _forgotten = SuggestionState(
  categoryId: chai.id,
  restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
  forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 10, 30)),
);

void main() {
  late FakeSuggestionStateRepository states;
  late RestoreUsual restore;

  setUp(() {
    states = FakeSuggestionStateRepository(<SuggestionState>[_forgotten, const SuggestionState(categoryId: 1)]);
    restore = RestoreUsual(states: states);
  });

  group('RestoreUsual', () {
    test('puts the previous state back (E68)', () async {
      final SuggestionState resting = SuggestionState(
        categoryId: chai.id,
        quietOn: const Option<CalendarDate>.of(CalendarDate(2026, 10, 20)),
        restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 19)),
      );

      final Either<Failure, Unit> result =
          await restore(ForgottenUsual(categoryId: chai.id, previous: Option<SuggestionState>.of(resting))).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(states.states[chai.id], resting);
      expect(states.states[1], const SuggestionState(categoryId: 1));
    });

    test('with no previous state the row is removed (E68)', () async {
      final Either<Failure, Unit> result =
          await restore(ForgottenUsual(categoryId: chai.id, previous: const Option<SuggestionState>.none())).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(states.states, <int, SuggestionState>{1: const SuggestionState(categoryId: 1)});
    });

    test('Forget then Undo leaves the states as they were', () async {
      states.states.remove(chai.id);
      final Map<int, SuggestionState> before = Map<int, SuggestionState>.of(states.states);
      final ForgottenUsual forgotten = (await ForgetUsual(states: states, clock: FakeClock(DateTime(2026, 10, 26, 10, 30)))(chai.id).run())
          .getOrElse((Failure failure) => fail(failure.message));

      await restore(forgotten).run();

      expect(states.states, before);
    });

    test('a failed put is returned and changes nothing', () async {
      states.writeFailure = DatabaseFailure('write');

      final Either<Failure, Unit> result = await restore(
        ForgottenUsual(categoryId: chai.id, previous: Option<SuggestionState>.of(SuggestionState(categoryId: chai.id))),
      ).run();

      expect(result.getLeft().toNullable(), states.writeFailure);
      expect(states.states[chai.id], _forgotten);
    });

    test('a failed remove is returned and changes nothing', () async {
      states.writeFailure = DatabaseFailure('write');

      final Either<Failure, Unit> result =
          await restore(ForgottenUsual(categoryId: chai.id, previous: const Option<SuggestionState>.none())).run();

      expect(result.getLeft().toNullable(), states.writeFailure);
      expect(states.states[chai.id], _forgotten);
    });
  });
}
