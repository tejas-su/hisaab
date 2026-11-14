import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/usecase/mark_missed_log_asked.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';

void main() {
  late FakeSuggestionStateRepository states;
  late MarkMissedLogAsked markAsked;

  setUp(() {
    states = FakeSuggestionStateRepository();
    markAsked = MarkMissedLogAsked(states: states, clock: FakeClock(DateTime(2026, 10, 27, 15, 30)));
  });

  group('MarkMissedLogAsked', () {
    test('writes today\'s date from the clock and nothing else (D172)', () async {
      expect(await markAsked(1).run(), Either<Failure, Unit>.right(unit));

      expect(
        states.states[1],
        const SuggestionState(categoryId: 1, askedOn: Option<CalendarDate>.of(CalendarDate(2026, 10, 27))),
      );
    });

    test('keeps the quiet state it finds', () async {
      states.states[1] = const SuggestionState(categoryId: 1, quietOn: Option<CalendarDate>.of(CalendarDate(2026, 10, 20)));

      await markAsked(1).run();

      expect(states.states[1]!.quietOn, const Option<CalendarDate>.of(CalendarDate(2026, 10, 20)));
    });

    test('a failed write is returned', () async {
      states.writeFailure = DatabaseFailure('write');

      expect((await markAsked(1).run()).getLeft().toNullable(), states.writeFailure);
    });
  });
}
