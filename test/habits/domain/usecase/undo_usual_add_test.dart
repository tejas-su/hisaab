import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/usecase/undo_usual_add.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const CalendarDate _today = WorkedExample.today;
const Option<CalendarDate> _quietToday = Option<CalendarDate>.of(_today);

void main() {
  late Entry added;
  late Entry other;
  late FakeLedgerRepository ledger;
  late FakeSuggestionStateRepository states;
  late UndoUsualAdd undo;

  setUp(() {
    added = entryAt(900, chai, 20, DateTime(2026, 10, 26, 10, 5));
    other = entryAt(901, food, 120, DateTime(2026, 10, 26, 9));
    ledger = FakeLedgerRepository(<Entry>[added, other]);
    states = FakeSuggestionStateRepository();
    undo = UndoUsualAdd(states: states, ledger: ledger, clock: FakeClock(WorkedExample.now));
  });

  tearDown(() => ledger.dispose());

  group('UndoUsualAdd', () {
    test('deletes the entry and quiets its category today (BR-10, E63)', () async {
      final Either<Failure, Unit> result = await undo(added).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(ledger.entries, <Entry>[other]);
      expect(states.states, <int, SuggestionState>{chai.id: SuggestionState(categoryId: chai.id, quietOn: _quietToday)});
    });

    test('a second Undo within 14 days rests it 30 days', () async {
      states.states[chai.id] = SuggestionState(categoryId: chai.id, quietOn: Option<CalendarDate>.of(_today.addDays(-14)));

      await undo(added).run();

      expect(
        states.states[chai.id],
        SuggestionState(
          categoryId: chai.id,
          quietOn: _quietToday,
          restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
        ),
      );
    });

    test('a second Undo 15 days later only quiets', () async {
      states.states[chai.id] = SuggestionState(categoryId: chai.id, quietOn: Option<CalendarDate>.of(_today.addDays(-15)));

      await undo(added).run();

      expect(states.states[chai.id], SuggestionState(categoryId: chai.id, quietOn: _quietToday));
    });

    test('another category\'s state is left alone', () async {
      final SuggestionState foodState = SuggestionState(categoryId: food.id, quietOn: _quietToday);
      states.states[food.id] = foodState;

      await undo(added).run();

      expect(states.states[food.id], foodState);
      expect(states.states[chai.id]?.restUntil, const Option<CalendarDate>.none());
    });

    test('the quiet state is stored before the entry is deleted', () async {
      Option<CalendarDate> quietOnWhenDeleted = const Option<CalendarDate>.none();
      final StreamSubscription<void> changes = ledger.changes.listen(
        (void _) => quietOnWhenDeleted = states.states[chai.id]?.quietOn ?? const Option<CalendarDate>.none(),
      );
      addTearDown(changes.cancel);

      await undo(added).run();

      expect(quietOnWhenDeleted, _quietToday);
      expect(states.calls, <String>['of:${chai.id}', 'put:${chai.id}']);
    });

    test('an entry already gone: EntryNotFoundFailure, and the category is still quiet', () async {
      await ledger.delete(added.id).run();

      final Either<Failure, Unit> result = await undo(added).run();

      expect(result.getLeft().toNullable(), isA<EntryNotFoundFailure>());
      expect(states.states[chai.id]?.quietOn, _quietToday);
    });

    test('a state failure deletes nothing', () async {
      states.failure = DatabaseFailure('states');

      final Either<Failure, Unit> result = await undo(added).run();

      expect(result.getLeft().toNullable(), states.failure);
      expect(ledger.entries, <Entry>[added, other]);
    });

    test('a failed write of the quiet state deletes nothing', () async {
      states.writeFailure = DatabaseFailure('write');

      final Either<Failure, Unit> result = await undo(added).run();

      expect(result.getLeft().toNullable(), states.writeFailure);
      expect(ledger.entries, <Entry>[added, other]);
      expect(states.states, isEmpty);
    });
  });
}
