import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
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
final DateTime _now = DateTime(2026, 10, 26, 10, 5);

void main() {
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeSuggestionStateRepository states;
  late FakeClock clock;
  late UsualRowBloc bloc;

  UsualRowBloc build({int categoryId = 13}) => UsualRowBloc(
        categoryId: categoryId,
        getIndex: GetHabitIndex(ledger: ledger, categories: categories, states: states, clock: clock),
        forget: ForgetUsual(states: states, clock: clock),
        restore: RestoreUsual(states: states),
        clock: clock,
      );

  setUp(() {
    ledger = FakeLedgerRepository(chaiWeekdays(today: _today));
    categories = FakeCategoryRepository(<Category>[...seedCategories, chai]);
    states = FakeSuggestionStateRepository();
    clock = FakeClock(_now);
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  Matcher shown({DayType dayType = DayType.weekday, bool? fading}) => isA<UsualRowShown>()
      .having((UsualRowShown state) => state.habit.categoryId, 'category', chai.id)
      .having((UsualRowShown state) => state.habit.dayType, 'day type', dayType)
      .having((UsualRowShown state) => state.habit.fading, 'fading', fading ?? anything);

  group('UsualRowBloc load (FR-SE-2 AC-6)', () {
    test('starts empty', () => expect(bloc.state, const UsualRowEmpty()));

    test('a Regular habit is shown', () async {
      final Future<void> expectation = expectLater(bloc.stream, emits(shown()));

      await bloc.dispatch(const UsualRowLoadRequested());

      await expectation;
    });

    test('no habit stays empty', () async {
      ledger.entries.clear();

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('another category\'s habit is not shown', () async {
      await bloc.close();
      bloc = build(categoryId: food.id);

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('a failed load stays empty', () async {
      ledger.failure = DatabaseFailure('gone');

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('a failed reload empties the row', () async {
      await bloc.dispatch(const UsualRowLoadRequested());
      states.failure = const InvalidDataFailure('bad row');

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('on a weekend with only a weekday habit, the weekday habit is shown', () async {
      // Sat 24 Oct: Friday's entries are still before today, so the weekday habit holds.
      clock.current = DateTime(2026, 10, 24, 16);

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, shown());
    });

    test("with both, today's day type is shown", () async {
      ledger.entries.addAll(entriesOn(daysBefore(_today, DayType.weekend), chai, hour: 16, minute: 0, firstId: 401));

      await bloc.dispatch(const UsualRowLoadRequested());
      expect(bloc.state, shown());

      await bloc.close();
      // Sun 25 Oct, a weekend day: every weekend entry but its own is before today.
      clock.current = DateTime(2026, 10, 25, 9);
      bloc = build();
      await bloc.dispatch(const UsualRowLoadRequested());
      expect(bloc.state, shown(dayType: DayType.weekend));
    });

    test('a hidden category shows nothing (E59)', () async {
      await categories.setHidden(chai.id, hidden: true).run();

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('under 14 days of use: nothing (E67)', () async {
      final CalendarDate firstDay = _today.addDays(-13);
      ledger.entries.removeWhere((Entry entry) => entry.date.isBefore(firstDay));

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('a habit that missed 3 days is still shown', () async {
      final CalendarDate lastHit = _today.addDays(-6);
      ledger.entries.removeWhere((Entry entry) => entry.categoryId == chai.id && entry.date.isAfter(lastHit));

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, shown(fading: true));
    });

    test('a habit resting after two Undos is still shown, so it can be forgotten', () async {
      states.states[chai.id] = SuggestionState(
        categoryId: chai.id,
        quietOn: Option<CalendarDate>.of(_today),
        restUntil: Option<CalendarDate>.of(_today.addDays(30)),
      );

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, shown());
    });

    test('a slower, older load never lands last', () async {
      final Completer<void> slow = Completer<void>();
      ledger.nextReadGate = slow;
      bloc.add(const UsualRowLoadRequested());
      await pumpEventQueue();
      ledger.entries.clear();

      await bloc.dispatch(const UsualRowLoadRequested());
      expect(bloc.state, const UsualRowEmpty());
      slow.complete();
      await pumpEventQueue();

      expect(bloc.state, const UsualRowEmpty());
    });

    test('closing mid-load does not throw', () async {
      final Completer<void> slow = Completer<void>();
      ledger.nextReadGate = slow;
      bloc.add(const UsualRowLoadRequested());
      await pumpEventQueue();

      await expectLater(bloc.close(), completes);
      slow.complete();
      await pumpEventQueue();

      expect(bloc.state, const UsualRowEmpty());
    });
  });

  group('UsualRowBloc Forget (FR-SE-2 AC-6, BR-17)', () {
    final SuggestionState forgotten = SuggestionState(
      categoryId: chai.id,
      restUntil: Option<CalendarDate>.of(_today.addDays(30)),
      forgottenAt: Option<DateTime>.of(_now),
    );

    setUp(() => bloc.dispatch(const UsualRowLoadRequested()));

    test('Forget hides the row and stores forgottenAt and a 30-day rest', () async {
      await bloc.dispatch(const UsualRowForgetRequested());

      expect(
        bloc.state,
        UsualRowForgotten(ForgottenUsual(categoryId: chai.id, previous: const Option<SuggestionState>.none())),
      );
      expect(states.states, <int, SuggestionState>{chai.id: forgotten});
    });

    test('a failed Forget keeps the row', () async {
      states.writeFailure = DatabaseFailure('locked');

      await bloc.dispatch(const UsualRowForgetRequested());

      expect(bloc.state, shown());
      expect(states.states, isEmpty);
    });

    test('Forget with no row shown stores nothing', () async {
      ledger.entries.clear();
      await bloc.dispatch(const UsualRowLoadRequested());

      await bloc.dispatch(const UsualRowForgetRequested());

      expect(bloc.state, const UsualRowEmpty());
      expect(states.calls, isNot(contains('put:${chai.id}')));
    });

    test('a second Forget tap is dropped', () async {
      bloc
        ..add(const UsualRowForgetRequested())
        ..add(const UsualRowForgetRequested());
      await pumpEventQueue();

      expect(states.calls.where((String call) => call == 'put:${chai.id}'), hasLength(1));
      expect(
        bloc.state,
        UsualRowForgotten(ForgottenUsual(categoryId: chai.id, previous: const Option<SuggestionState>.none())),
      );
    });

    test('a reload after Forget finds no habit', () async {
      await bloc.dispatch(const UsualRowForgetRequested());

      await bloc.dispatch(const UsualRowLoadRequested());

      expect(bloc.state, const UsualRowEmpty());
    });

    test('Undo puts the previous state back and the row returns (E68)', () async {
      await bloc.dispatch(const UsualRowForgetRequested());

      await bloc.dispatch(const UsualRowForgetUndone());

      expect(states.states, isEmpty);
      expect(bloc.state, shown());
    });

    test('Undo after forgetting a resting habit leaves it resting as before (E68)', () async {
      final SuggestionState resting = SuggestionState(
        categoryId: chai.id,
        quietOn: Option<CalendarDate>.of(_today.addDays(-2)),
        restUntil: Option<CalendarDate>.of(_today.addDays(28)),
      );
      states.states[chai.id] = resting;
      await bloc.dispatch(const UsualRowForgetRequested());
      expect(states.states[chai.id]?.forgottenAt, Option<DateTime>.of(_now));

      await bloc.dispatch(const UsualRowForgetUndone());

      expect(states.states, <int, SuggestionState>{chai.id: resting});
      expect(bloc.state, shown());
    });

    test('a second Undo tap is dropped', () async {
      await bloc.dispatch(const UsualRowForgetRequested());

      bloc
        ..add(const UsualRowForgetUndone())
        ..add(const UsualRowForgetUndone());
      await pumpEventQueue();

      expect(states.calls.where((String call) => call == 'remove:${chai.id}'), hasLength(1));
      expect(bloc.state, shown());
    });

    test('a failed Undo leaves it forgotten and the row empty', () async {
      await bloc.dispatch(const UsualRowForgetRequested());
      states.writeFailure = DatabaseFailure('locked');

      await bloc.dispatch(const UsualRowForgetUndone());

      expect(states.states, <int, SuggestionState>{chai.id: forgotten});
      expect(bloc.state, const UsualRowEmpty());
    });

    test('Undo with nothing forgotten writes nothing', () async {
      await bloc.dispatch(const UsualRowForgetUndone());

      expect(states.calls.where((String call) => call.startsWith('remove') || call.startsWith('put')), isEmpty);
      expect(bloc.state, shown());
    });
  });

  group('UsualRowBloc events and states', () {
    test('two loads of the same habit give equal shown states', () async {
      await bloc.dispatch(const UsualRowLoadRequested());
      final UsualRowState first = bloc.state;
      final UsualRowBloc other = build();
      addTearDown(other.close);

      await other.dispatch(const UsualRowLoadRequested());

      expect(other.state, isA<UsualRowShown>());
      expect(other.state, first);
      expect(identical(other.state, first), isFalse);
    });

    test('compare by their fields', () {
      final ForgottenUsual forgotten = ForgottenUsual(categoryId: chai.id, previous: const Option<SuggestionState>.none());
      expect(const UsualRowLoadRequested(), const UsualRowLoadRequested());
      expect(const UsualRowForgetRequested(), const UsualRowForgetRequested());
      expect(const UsualRowForgetUndone(), const UsualRowForgetUndone());
      expect(const UsualRowForgetRequested(), isNot(const UsualRowForgetUndone()));
      expect(const UsualRowLoadRequested().props, isEmpty);
      expect(const UsualRowEmpty(), const UsualRowEmpty());
      expect(UsualRowForgotten(forgotten), UsualRowForgotten(forgotten));
      expect(
        UsualRowForgotten(forgotten),
        isNot(UsualRowForgotten(ForgottenUsual(categoryId: food.id, previous: const Option<SuggestionState>.none()))),
      );
    });
  });
}
