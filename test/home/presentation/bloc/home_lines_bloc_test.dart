import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_bloc.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_event.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_state.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

const CalendarDate _monday = CalendarDate(2026, 10, 26);
final DateTime _threeThirty = DateTime(2026, 10, 26, 15, 30);

final UsualHabit _foodHabit = UsualHabit(
  categoryId: food.id,
  dayType: DayType.weekday,
  pooled: false,
  window: const TimeWindow(startMinute: 735, lengthMinutes: 105),
  amount: Money.fromMajor(55),
  hitDays: 18,
  activeDays: 20,
  lastHit: DateTime(2026, 10, 23, 13),
  fading: false,
);

HabitIndex _index({Set<int> loggedToday = const <int>{}}) =>
    HabitIndex(builtOn: _monday, habits: <UsualHabit>[_foodHabit], loggedToday: loggedToday, states: const <int, SuggestionState>{});

HomeLinesFacts _facts({
  HabitIndex? index,
  bool noIncome = false,
  bool overState = false,
  bool billLineShowing = false,
  bool noHabits = false,
}) =>
    HomeLinesFacts(
      index: noHabits ? null : (index ?? _index()),
      categories: seedCategories,
      now: _threeThirty,
      noIncome: noIncome,
      overState: overState,
      billLineShowing: billLineShowing,
    );

void main() {
  late FakeSuggestionStateRepository states;
  late FakeHaptics haptics;
  late FakeClock clock;
  late HomeLinesBloc bloc;

  setUp(() {
    states = FakeSuggestionStateRepository();
    haptics = FakeHaptics();
    clock = FakeClock(_threeThirty);
    bloc = HomeLinesBloc(
      markAsked: MarkMissedLogAsked(states: states, clock: clock),
      clock: clock,
      haptics: haptics,
    );
    addTearDown(bloc.close);
  });

  Future<void> decide([HomeLinesFacts? facts]) async {
    await bloc.dispatch(const HomeLinesPointReached());
    await bloc.dispatch(HomeLinesEvaluated(facts ?? _facts()));
  }

  group('HomeLinesBloc (FR-HO-3, D170)', () {
    test('before a point, nothing is decided', () async {
      await bloc.dispatch(HomeLinesEvaluated(_facts()));

      expect(bloc.state, const HomeLinesState());
    });

    test('a point latches until an evaluation', () async {
      await bloc.dispatch(const HomeLinesPointReached());

      expect(bloc.state.pointPending, isTrue);
      expect(bloc.state.missed, const Option<MissedLog>.none());
    });

    test('a point then an evaluation with a qualifying habit puts the line in state (AC-1)', () async {
      await decide();

      expect(bloc.state.missed.map((MissedLog line) => line.category), Option<Category>.of(food));
      expect(bloc.state.pointPending, isFalse);
      expect(bloc.state.asked, isFalse);
      expect(states.states, isEmpty);
    });

    for (final (String, HomeLinesFacts) blocked in <(String, HomeLinesFacts)>[
      ('No income', _facts(noIncome: true)),
      ('an over state', _facts(overState: true)),
      ('a bill line holding the slot', _facts(billLineShowing: true)),
      ('habits not loaded (E106)', _facts(noHabits: true)),
    ]) {
      test('an evaluation with ${blocked.$1} decides nothing and spends the point', () async {
        await decide(blocked.$2);
        await bloc.dispatch(HomeLinesEvaluated(_facts()));

        expect(bloc.state.missed, const Option<MissedLog>.none());
        expect(bloc.state.pointPending, isFalse);
      });
    }

    test('evaluating twice for one point is ignored', () async {
      await decide();
      await bloc.dispatch(const HomeLinesTrayClosed());
      await bloc.dispatch(HomeLinesEntryLogged(food.id));
      await bloc.dispatch(HomeLinesEvaluated(_facts()));

      expect(bloc.state.missed, const Option<MissedLog>.none());
    });

    test('a new point decides again, and the new line is a new serial', () async {
      await decide();
      final int first = bloc.state.serial;

      await decide();

      expect(bloc.state.serial, first + 1);
    });

    test('Shown writes asked_on once and sets asked (AC-4)', () async {
      await decide();

      await bloc.dispatch(const HomeLinesShown());
      await bloc.dispatch(const HomeLinesShown());

      expect(states.states[food.id]!.askedOn, const Option<CalendarDate>.of(_monday));
      expect(states.calls.where((String call) => call.startsWith('asked')), <String>['asked:${food.id}']);
      expect(bloc.state.asked, isTrue);
    });

    test('Shown without a line writes nothing', () async {
      await bloc.dispatch(const HomeLinesShown());

      expect(states.calls, isEmpty);
    });

    test('a tap writes asked once, sets tapped, ticks once; a second tap is dropped (AC-2)', () async {
      await decide();
      bloc
        ..add(const HomeLinesTapped())
        ..add(const HomeLinesTapped());
      await pumpEventQueue();

      expect(bloc.state.tapped, isTrue);
      expect(bloc.state.asked, isTrue);
      expect(haptics.events, <String>['tick']);
      expect(states.calls.where((String call) => call.startsWith('asked')), <String>['asked:${food.id}']);
    });

    test('a tap on a line that was already shown writes nothing more', () async {
      await decide();
      await bloc.dispatch(const HomeLinesShown());

      await bloc.dispatch(const HomeLinesTapped());

      expect(states.calls.where((String call) => call.startsWith('asked')), hasLength(1));
    });

    test('a tap without a line does nothing', () async {
      await bloc.dispatch(const HomeLinesTapped());

      expect(haptics.events, isEmpty);
      expect(bloc.state.tapped, isFalse);
    });

    test('the tray closing after a tap removes the line and writes nothing more, with no haptic (AC-3, E104)', () async {
      await decide();
      await bloc.dispatch(const HomeLinesTapped());
      final List<String> before = List<String>.of(states.calls);

      await bloc.dispatch(const HomeLinesTrayClosed());

      expect(bloc.state.missed, const Option<MissedLog>.none());
      expect(bloc.state.tapped, isFalse);
      expect(states.calls, before);
      expect(haptics.events, <String>['tick']);
    });

    test('a tray closing never decides, and never removes a line that was not tapped (E105, AC-4)', () async {
      await bloc.dispatch(const HomeLinesTrayClosed());
      expect(bloc.state.missed, const Option<MissedLog>.none());

      await decide();
      await bloc.dispatch(const HomeLinesTrayClosed());

      expect(bloc.state.missed.isSome(), isTrue);
    });

    test('an entry logged in the line\'s category removes it; in another does not (L8)', () async {
      await decide();

      await bloc.dispatch(HomeLinesEntryLogged(chai.id));
      expect(bloc.state.missed.isSome(), isTrue);
      await bloc.dispatch(HomeLinesEntryLogged(food.id));

      expect(bloc.state.missed, const Option<MissedLog>.none());
    });

    test('the gate closing in the line\'s category removes it; in another does not (L8)', () async {
      await decide();

      await bloc.dispatch(HomeLinesGateClosed(chai.id));
      expect(bloc.state.missed.isSome(), isTrue);
      await bloc.dispatch(HomeLinesGateClosed(food.id));

      expect(bloc.state.missed, const Option<MissedLog>.none());
    });

    test('a bill line taking the slot removes it and it does not come back (E108)', () async {
      await decide();

      await bloc.dispatch(const HomeLinesSlotTaken());
      await bloc.dispatch(HomeLinesEvaluated(_facts()));

      expect(bloc.state.missed, const Option<MissedLog>.none());
    });

    test('midnight removes the line and clears a latched point (L8)', () async {
      await decide();
      await bloc.dispatch(const HomeLinesPointReached());

      await bloc.dispatch(const HomeLinesMidnight());
      await bloc.dispatch(HomeLinesEvaluated(_facts()));

      expect(bloc.state.missed, const Option<MissedLog>.none());
      expect(bloc.state.pointPending, isFalse);
    });

    test('a removal never evaluates: no event but Evaluated can add a line (D170)', () async {
      final List<HomeLinesEvent> removals = <HomeLinesEvent>[
        const HomeLinesShown(),
        const HomeLinesTapped(),
        const HomeLinesTrayClosed(),
        HomeLinesEntryLogged(food.id),
        HomeLinesGateClosed(food.id),
        const HomeLinesSlotTaken(),
        const HomeLinesMidnight(),
        const HomeLinesPointReached(),
      ];

      for (final HomeLinesEvent event in removals) {
        await bloc.dispatch(event);
        expect(bloc.state.missed, const Option<MissedLog>.none());
      }
    });

    test('after asking, a later point the same day decides nothing, though the habit index is stale (L3)', () async {
      await decide();
      await bloc.dispatch(const HomeLinesShown());

      await decide();

      expect(bloc.state.missed, const Option<MissedLog>.none());
    });

    test('the next day asks again', () async {
      await decide();
      await bloc.dispatch(const HomeLinesShown());
      final HomeLinesFacts tomorrow = HomeLinesFacts(
        index: HabitIndex(
          builtOn: _monday.addDays(1),
          habits: <UsualHabit>[_foodHabit],
          loggedToday: const <int>{},
          states: const <int, SuggestionState>{},
        ),
        categories: seedCategories,
        now: DateTime(2026, 10, 27, 15, 30),
      );

      await decide(tomorrow);

      expect(bloc.state.missed.isSome(), isTrue);
    });

    test('a failed asked write keeps the line and the state is not asked', () async {
      await decide();
      states.writeFailure = DatabaseFailure('write');

      await bloc.dispatch(const HomeLinesShown());

      expect(bloc.state.missed.isSome(), isTrue);
      expect(bloc.state.asked, isFalse);
    });

    test('closing mid-write does not throw', () async {
      await decide();
      bloc.add(const HomeLinesShown());

      await expectLater(bloc.close(), completes);
    });

    test('events and facts compare by value', () {
      expect(HomeLinesEvaluated(_facts()), HomeLinesEvaluated(_facts()));
      expect(HomeLinesEvaluated(_facts()), isNot(HomeLinesEvaluated(_facts(noIncome: true))));
      expect(HomeLinesEntryLogged(1), HomeLinesEntryLogged(1));
      expect(HomeLinesEntryLogged(1), isNot(HomeLinesEntryLogged(2)));
      expect(HomeLinesGateClosed(1), HomeLinesGateClosed(1));
      // ignore: prefer_const_constructors, a second instance, so == reads the inherited props rather than short-circuiting on identity
      expect(const HomeLinesShown(), HomeLinesShown());
      expect(const HomeLinesTapped(), const HomeLinesTapped());
      expect(const HomeLinesTrayClosed(), const HomeLinesTrayClosed());
      expect(const HomeLinesPointReached(), const HomeLinesPointReached());
      expect(const HomeLinesSlotTaken(), const HomeLinesSlotTaken());
      expect(const HomeLinesMidnight(), const HomeLinesMidnight());
    });
  });
}
