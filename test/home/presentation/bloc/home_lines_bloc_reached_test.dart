import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/domain/entities/reached_line.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_bloc.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_event.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const CalendarDate _monday = CalendarDate(2026, 10, 26);
final DateTime _threeThirty = DateTime(2026, 10, 26, 15, 30);
final Money _target = Money.fromMajor(12000);

final RecurringRule _insurance = WorkedExample.insurance.copyWith(target: Option<Money>.of(_target));

final UsualHabit _foodHabit = UsualHabit(
  categoryId: 1,
  dayType: DayType.weekday,
  pooled: false,
  window: const TimeWindow(startMinute: 735, lengthMinutes: 105),
  amount: Money.fromMajor(55),
  hitDays: 18,
  activeDays: 20,
  lastHit: DateTime(2026, 10, 23, 13),
  fading: false,
);

ReachedLine _line({bool pending = true}) => ReachedLine(saving: _insurance, target: _target, pending: pending);

HomeLinesFacts _facts({
  Option<ReachedLine>? reached,
  bool installDue = true,
  bool noIncome = false,
  bool overState = false,
  bool billLineShowing = false,
}) =>
    HomeLinesFacts(
      index: HabitIndex(builtOn: _monday, habits: <UsualHabit>[_foodHabit], loggedToday: const <int>{}, states: const <int, SuggestionState>{}),
      categories: seedCategories,
      now: _threeThirty,
      noIncome: noIncome,
      overState: overState,
      billLineShowing: billLineShowing,
      installDue: installDue,
      reached: reached ?? Option<ReachedLine>.of(_line()),
    );

/// The reached line in the nudge slot (SPEC FR-HO-3 AC-R1 to AC-R5, BR-23, E144 to E150).
void main() {
  late FakeSuggestionStateRepository states;
  late FakeBudgetSettingsRepository settings;
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late HomeLinesBloc bloc;

  setUp(() {
    states = FakeSuggestionStateRepository();
    settings = FakeBudgetSettingsRepository();
    recurring = FakeRecurringRepository(<RecurringRule>[_insurance]);
    haptics = FakeHaptics();
    final FakeClock clock = FakeClock(_threeThirty);
    bloc = HomeLinesBloc(
      markAsked: MarkMissedLogAsked(states: states, clock: clock),
      clock: clock,
      haptics: haptics,
      settings: settings,
      recurring: recurring,
    );
    addTearDown(bloc.close);
  });

  Future<void> decide([HomeLinesFacts? facts]) async {
    await bloc.dispatch(const HomeLinesPointReached());
    await bloc.dispatch(HomeLinesEvaluated(facts ?? _facts()));
  }

  group('deciding (AC-R1)', () {
    test('a pending saving takes the slot at a point, unwritten until seen', () async {
      await decide();

      expect(bloc.state.reached, Option<ReachedLine>.of(_line()));
      expect(bloc.state.reachedMarked, isFalse);
      expect(bloc.state.serial, 1);
      expect(recurring.updates, isEmpty);
    });

    test('it outranks the install and missed-log lines: neither shows nor is asked', () async {
      await decide();

      expect(bloc.state.install, isFalse);
      expect(bloc.state.missed, const Option<MissedLog>.none());
      expect(states.calls.where((String c) => c.startsWith('asked')), isEmpty);
    });

    test('with no candidate the install line decides as before', () async {
      await decide(_facts(reached: const Option<ReachedLine>.none()));

      expect(bloc.state.reached, const Option<ReachedLine>.none());
      expect(bloc.state.install, isTrue);
    });

    final Map<String, HomeLinesFacts> waits = <String, HomeLinesFacts>{
      'a waiting or due-soon bill line': _facts(billLineShowing: true),
      'an over state': _facts(overState: true),
      'No income': _facts(noIncome: true),
    };
    for (final MapEntry<String, HomeLinesFacts> wait in waits.entries) {
      test('behind ${wait.key} it waits, unwritten (E149)', () async {
        await decide(wait.value);
        await bloc.dispatch(const HomeLinesReachedShown());

        expect(bloc.state.reached, const Option<ReachedLine>.none());
        expect(recurring.updates, isEmpty);
      });
    }

    test('a bill line that clears mid-day does not slide it in: only a point decides', () async {
      await decide(_facts(billLineShowing: true));

      await bloc.dispatch(HomeLinesEvaluated(_facts()));

      expect(bloc.state.reached, const Option<ReachedLine>.none());
    });

    test('a saving shown today holds the slot again at a later point, and is not written again (F2)', () async {
      await decide(_facts(reached: Option<ReachedLine>.of(_line(pending: false))));
      await bloc.dispatch(const HomeLinesReachedShown());

      expect(bloc.state.reached, Option<ReachedLine>.of(_line(pending: false)));
      expect(bloc.state.install, isFalse);
      expect(recurring.updates, isEmpty);
    });
  });

  group('shown (AC-R2)', () {
    test('is written once the line is on screen: target_reached_for = T and target_reached_on = today', () async {
      await decide();

      await bloc.dispatch(const HomeLinesReachedShown());
      await bloc.dispatch(const HomeLinesReachedShown());

      expect(recurring.updates, <RecurringRule>[
        _insurance.copyWith(targetReachedFor: Option<Money>.of(_target), targetReachedOn: const Option<CalendarDate>.of(_monday)),
      ]);
      expect(bloc.state.reachedMarked, isTrue);
    });

    test('keeps every other column of the rule (copyWith, never a rebuilt rule)', () async {
      await decide();

      await bloc.dispatch(const HomeLinesReachedShown());

      expect(recurring.updates.single.target, Option<Money>.of(_target));
      expect(recurring.updates.single.label, 'Insurance');
    });

    test('writes only the reached marker over the rule as stored, so an edit since is kept', () async {
      await decide();
      final RecurringRule edited = _insurance.copyWith(
        label: 'Car insurance',
        amount: Money.fromMajor(1500),
        nextDue: const CalendarDate(2026, 12, 5),
      );
      recurring.rules = <RecurringRule>[edited];

      await bloc.dispatch(const HomeLinesReachedShown());

      expect(recurring.rules.single, edited.copyWith(
        targetReachedFor: Option<Money>.of(_target),
        targetReachedOn: const Option<CalendarDate>.of(_monday),
      ));
    });

    test('a second report while the write is in flight writes once', () async {
      await decide();
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;

      bloc
        ..add(const HomeLinesReachedShown())
        ..add(const HomeLinesReachedShown());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(recurring.updates, hasLength(1));
    });

    test('a failed write leaves it pending and on screen, so it shows again at the next point', () async {
      await decide();
      recurring.failure = DatabaseFailure('locked');

      await bloc.dispatch(const HomeLinesReachedShown());

      expect(bloc.state.reachedMarked, isFalse);
      expect(bloc.state.reached.isSome(), isTrue);
    });

    test('with no line, a report writes nothing', () async {
      await decide(_facts(reached: const Option<ReachedLine>.none()));

      await bloc.dispatch(const HomeLinesReachedShown());

      expect(recurring.updates, isEmpty);
    });
  });

  group('tapped (AC-R5)', () {
    test('ticks and writes nothing; the line stays, still pending (AC-R5, AC-R2)', () async {
      await decide();

      await bloc.dispatch(const HomeLinesReachedTapped());

      expect(haptics.events, <String>['tick']);
      expect(recurring.updates, isEmpty);
      expect(bloc.state.reached, Option<ReachedLine>.of(_line()));
      expect(bloc.state.reachedMarked, isFalse);
    });

    test('a saving renamed since the point is not reverted by a tap (regression)', () async {
      await decide();
      await recurring.update(_insurance.copyWith(label: 'Car insurance')).run();
      recurring.updates.clear();

      await bloc.dispatch(const HomeLinesReachedTapped());

      expect(recurring.updates, isEmpty);
      expect(recurring.rules.single.label, 'Car insurance');
    });

    test('after the line was seen, a tap ticks and writes nothing more; a later tap ticks again (no tapped guard)', () async {
      await decide();
      await bloc.dispatch(const HomeLinesReachedShown());

      await bloc.dispatch(const HomeLinesReachedTapped());
      await bloc.dispatch(const HomeLinesReachedTapped());

      expect(haptics.events, <String>['tick', 'tick']);
      expect(recurring.updates, hasLength(1));
    });

    test('with no line a tap does nothing', () async {
      await decide(_facts(reached: const Option<ReachedLine>.none(), installDue: false));

      await bloc.dispatch(const HomeLinesReachedTapped());

      expect(haptics.events, isEmpty);
    });
  });

  group('leaving (AC-R3)', () {
    test('at midnight', () async {
      await decide();

      await bloc.dispatch(const HomeLinesMidnight());

      expect(bloc.state.reached, const Option<ReachedLine>.none());
      expect(bloc.state.reachedMarked, isFalse);
    });

    test('when it no longer qualifies at a reload (F3)', () async {
      await decide();
      await bloc.dispatch(const HomeLinesReachedShown());

      await bloc.dispatch(const HomeLinesReachedGone());

      expect(bloc.state.reached, const Option<ReachedLine>.none());
    });

    test('when a bill line takes the slot', () async {
      await decide();

      await bloc.dispatch(const HomeLinesSlotTaken());

      expect(bloc.state.reached, const Option<ReachedLine>.none());
    });
  });
}
