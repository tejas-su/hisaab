import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const CalendarDate _today = WorkedExample.today;
const Option<UsualAdd> _noAdd = Option<UsualAdd>.none();

void main() {
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeSuggestionStateRepository states;
  late HabitsBloc bloc;

  /// The entry a pill tap saved today, and the add the route hands to the bloc.
  final Entry tapped = entryAt(900, chai, 20, DateTime(2026, 10, 26, 10, 5));
  final UsualAdd added = UsualAdd(entry: tapped, category: chai);

  setUp(() {
    ledger = FakeLedgerRepository(chaiWeekdays(today: _today));
    categories = FakeCategoryRepository(<Category>[...seedCategories, chai]);
    states = FakeSuggestionStateRepository();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 10, 5));
    bloc = HabitsBloc(
      getIndex: GetHabitIndex(ledger: ledger, categories: categories, states: states, clock: clock),
      undoAdd: UndoUsualAdd(states: states, ledger: ledger, clock: clock),
      ledger: ledger,
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  HabitsReady ready() => bloc.state as HabitsReady;

  Matcher readyWith({required Matcher habits, Option<UsualAdd> added = _noAdd}) => isA<HabitsReady>()
      .having((HabitsReady state) => state.index.habits.map((UsualHabit habit) => habit.categoryId), 'habit categories', habits)
      .having((HabitsReady state) => state.added, 'added', added);

  group('HabitsBloc load', () {
    test('starts loading', () => expect(bloc.state, const HabitsLoading()));

    test('a load emits the index', () async {
      final Future<void> expectation = expectLater(bloc.stream, emits(readyWith(habits: equals(<int>[chai.id]))));

      await bloc.dispatch(const HabitsLoadRequested());

      await expectation;
      expect(ready().index.builtOn, _today);
      expect(ready().index.habits.single.amount, Money.fromMajor(20));
    });

    test('an empty ledger loads an empty index', () async {
      ledger.entries.clear();

      await bloc.dispatch(const HabitsLoadRequested());

      expect(bloc.state, HabitsReady(HabitIndex.empty(_today)));
    });

    test('a failed first load stays loading', () async {
      ledger.failure = DatabaseFailure('gone');
      final List<HabitsState> emitted = <HabitsState>[];
      final StreamSubscription<HabitsState> subscription = bloc.stream.listen(emitted.add);
      addTearDown(subscription.cancel);

      await bloc.dispatch(const HabitsLoadRequested());

      expect(bloc.state, const HabitsLoading());
      expect(emitted, isEmpty);
    });

    test('a failed reload keeps the last index', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      final HabitsState loaded = bloc.state;
      states.failure = const InvalidDataFailure('bad row');

      await bloc.dispatch(const HabitsLoadRequested());

      expect(bloc.state, loaded);
      expect(ready().index.habits, hasLength(1));
    });

    test('a load after a failed one recovers', () async {
      categories.failure = DatabaseFailure('gone');
      await bloc.dispatch(const HabitsLoadRequested());
      categories.failure = null;

      await bloc.dispatch(const HabitsLoadRequested());

      expect(bloc.state, readyWith(habits: equals(<int>[chai.id])));
    });

    test('a ledger change reloads', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      expect(ready().index.loggedToday, isEmpty);

      await ledger.add(EntryDraft(amount: Money.fromMajor(20), kind: EntryKind.spent, categoryId: chai.id, date: _today)).run();
      await pumpEventQueue();

      expect(ready().index.loggedToday, <int>{chai.id});
    });

    test('a slower, older load never lands last', () async {
      final Completer<void> slow = Completer<void>();
      ledger.nextReadGate = slow;
      bloc.add(const HabitsLoadRequested());
      await pumpEventQueue();
      ledger.entries.clear();

      await bloc.dispatch(const HabitsLoadRequested());
      expect(ready().index.habits, isEmpty);
      slow.complete();
      await pumpEventQueue();

      expect(ready().index.habits, isEmpty);
    });

    test('closing mid-load does not throw', () async {
      final Completer<void> slow = Completer<void>();
      ledger.nextReadGate = slow;
      bloc.add(const HabitsLoadRequested());
      await pumpEventQueue();

      await expectLater(bloc.close(), completes);
      slow.complete();
      await pumpEventQueue();

      expect(bloc.state, const HabitsLoading());
    });
  });

  group('HabitsBloc usual add (BR-10)', () {
    setUp(() => ledger.entries.add(tapped));

    test('a usual add is offered once, then cleared by the next emit', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      final HabitIndex index = ready().index;

      await bloc.dispatch(HabitsUsualAdded(added));
      expect(bloc.state, HabitsReady(index, added: Option<UsualAdd>.of(added)));

      await ledger.add(EntryDraft(amount: Money.fromMajor(50), kind: EntryKind.spent, categoryId: food.id, date: _today)).run();
      await pumpEventQueue();

      expect(ready().added, _noAdd);
      expect(ready().index.loggedToday, <int>{chai.id, food.id});
    });

    test('a usual add while loading emits nothing', () async {
      final List<HabitsState> emitted = <HabitsState>[];
      final StreamSubscription<HabitsState> subscription = bloc.stream.listen(emitted.add);
      addTearDown(subscription.cancel);

      await bloc.dispatch(HabitsUsualAdded(added));

      expect(bloc.state, const HabitsLoading());
      expect(emitted, isEmpty);
    });

    test('Undo deletes the entry, quiets the category and reloads (E63)', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      await bloc.dispatch(HabitsUsualAdded(added));
      expect(ready().index.loggedToday, <int>{chai.id});

      await bloc.dispatch(HabitsUsualUndoRequested(added));

      final SuggestionState quiet = SuggestionState(categoryId: chai.id, quietOn: const Option<CalendarDate>.of(_today));
      expect(ledger.entries, isNot(contains(tapped)));
      expect(states.states, <int, SuggestionState>{chai.id: quiet});
      expect(ready().added, _noAdd);
      expect(ready().index.loggedToday, isEmpty);
      expect(ready().index.states, <int, SuggestionState>{chai.id: quiet});
    });

    test('after an Undo the detector offers nothing for the rest of the day', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      await bloc.dispatch(HabitsUsualUndoRequested(added));

      expect(
        UsualSpendDetector.suggest(ready().index, now: DateTime(2026, 10, 26, 10, 6), categories: categories.categories),
        const Option<UsualSpend>.none(),
      );
    });

    test('a failed Undo deletes nothing and the offer is gone', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      await bloc.dispatch(HabitsUsualAdded(added));
      states.writeFailure = DatabaseFailure('write');

      await bloc.dispatch(HabitsUsualUndoRequested(added));

      expect(ledger.entries, contains(tapped));
      expect(states.states, isEmpty);
      expect(ready().added, _noAdd);
      expect(ready().index.loggedToday, <int>{chai.id});
    });

    test('a second Undo while the first is in flight is dropped', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      await bloc.dispatch(HabitsUsualAdded(added));
      final Completer<void> slow = Completer<void>();
      ledger.nextDeleteGate = slow;

      bloc
        ..add(HabitsUsualUndoRequested(added))
        ..add(HabitsUsualUndoRequested(added));
      await pumpEventQueue();
      slow.complete();
      await pumpEventQueue();

      expect(states.calls.where((String call) => call == 'put:${chai.id}'), hasLength(1));
      expect(states.states[chai.id]?.restUntil, const Option<CalendarDate>.none());
      expect(ledger.entries, isNot(contains(tapped)));
    });

    test('closing mid-undo does not throw', () async {
      await bloc.dispatch(const HabitsLoadRequested());
      final Completer<void> slow = Completer<void>();
      ledger.nextDeleteGate = slow;
      bloc.add(HabitsUsualUndoRequested(added));
      await pumpEventQueue();

      await expectLater(bloc.close(), completes);
      slow.complete();
      await pumpEventQueue();

      expect(bloc.state, isA<HabitsReady>());
    });
  });
}
