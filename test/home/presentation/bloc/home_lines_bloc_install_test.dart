import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_bloc.dart';
import 'package:hisaab/home/presentation/bloc/home_lines_event.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
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

HomeLinesFacts _facts({bool installDue = true, bool noIncome = false, bool overState = false, bool billLineShowing = false}) => HomeLinesFacts(
      index: HabitIndex(builtOn: _monday, habits: <UsualHabit>[_foodHabit], loggedToday: const <int>{}, states: const <int, SuggestionState>{}),
      categories: seedCategories,
      now: _threeThirty,
      noIncome: noIncome,
      overState: overState,
      billLineShowing: billLineShowing,
      installDue: installDue,
    );

/// The one-time install line in the nudge slot (FR-HO-3, FR-FX-1, E107 to E109).
void main() {
  late FakeSuggestionStateRepository states;
  late FakeBudgetSettingsRepository settings;
  late FakeHaptics haptics;
  late HomeLinesBloc bloc;

  setUp(() {
    states = FakeSuggestionStateRepository();
    settings = FakeBudgetSettingsRepository();
    haptics = FakeHaptics();
    final FakeClock clock = FakeClock(_threeThirty);
    bloc = HomeLinesBloc(
      markAsked: MarkMissedLogAsked(states: states, clock: clock),
      clock: clock,
      haptics: haptics,
      settings: settings,
    );
    addTearDown(bloc.close);
  });

  Future<void> decide([HomeLinesFacts? facts]) async {
    await bloc.dispatch(const HomeLinesPointReached());
    await bloc.dispatch(HomeLinesEvaluated(facts ?? _facts()));
  }

  group('deciding', () {
    test('a mid-cycle install shows the line at the first point', () async {
      await decide();

      expect(bloc.state.install, isTrue);
      expect(bloc.state.serial, 1);
    });

    test('it outranks the missed-log line: the habit is neither shown nor asked', () async {
      await decide();

      expect(bloc.state.missed, const Option<MissedLog>.none());
      expect(states.calls.where((String c) => c.startsWith('asked')), isEmpty);
    });

    test('with no install due the missed-log line decides as before', () async {
      await decide(_facts(installDue: false));

      expect(bloc.state.install, isFalse);
      expect(bloc.state.missed.isSome(), isTrue);
    });

    test('a bill line in the slot, an over state or no income: not shown, and nothing is written', () async {
      for (final HomeLinesFacts facts in <HomeLinesFacts>[
        _facts(billLineShowing: true),
        _facts(overState: true),
        _facts(noIncome: true),
      ]) {
        await decide(facts);

        expect(bloc.state.install, isFalse);
      }
      expect(settings.installSeen, isFalse);
    });

    test('a cleared bill line does not slide it in mid-day: only a point decides (E108)', () async {
      await decide(_facts(billLineShowing: true));

      await bloc.dispatch(HomeLinesEvaluated(_facts()));

      expect(bloc.state.install, isFalse);
    });
  });

  group('seen', () {
    test('is written once the line is on screen, and never twice', () async {
      await decide();

      await bloc.dispatch(const HomeLinesInstallShown());
      await bloc.dispatch(const HomeLinesInstallShown());

      expect(settings.installSeen, isTrue);
      expect(bloc.state.installMarked, isTrue);
      expect(bloc.state.install, isTrue);
    });

    test('a shown report with no line does nothing', () async {
      await bloc.dispatch(const HomeLinesInstallShown());

      expect(settings.installSeen, isFalse);
    });

    test('a failed write is not fatal and leaves the line to be marked again', () async {
      await decide();
      settings.seenFailure = DatabaseFailure('down');

      await bloc.dispatch(const HomeLinesInstallShown());

      expect(bloc.state.installMarked, isFalse);
      expect(bloc.state.install, isTrue);
    });

    test('a tap ticks once, marks it seen, and the line goes when the sheet closes', () async {
      await decide();

      await bloc.dispatch(const HomeLinesInstallTapped());
      await bloc.dispatch(const HomeLinesInstallTapped());
      expect(haptics.events, <String>['tick']);
      expect(settings.installSeen, isTrue);
      expect(bloc.state.install, isTrue);

      await bloc.dispatch(const HomeLinesTrayClosed());

      expect(bloc.state.install, isFalse);
    });

    test('a bill line taking the slot, or midnight, removes it', () async {
      await decide();
      await bloc.dispatch(const HomeLinesSlotTaken());
      expect(bloc.state.install, isFalse);

      await decide();
      await bloc.dispatch(const HomeLinesMidnight());
      expect(bloc.state.install, isFalse);
    });

    test('a fix that used it up removes it unless it was already on screen', () async {
      await decide();
      await bloc.dispatch(const HomeLinesInstallConsumed());
      expect(bloc.state.install, isFalse);

      await decide();
      await bloc.dispatch(const HomeLinesInstallShown());
      await bloc.dispatch(const HomeLinesInstallConsumed());
      expect(bloc.state.install, isTrue);
    });
  });

  test('without a settings repository the line is never decided (older constructions)', () async {
    final HomeLinesBloc plain = HomeLinesBloc(
      markAsked: MarkMissedLogAsked(states: states, clock: FakeClock(_threeThirty)),
      clock: FakeClock(_threeThirty),
      haptics: haptics,
    );
    addTearDown(plain.close);
    await plain.dispatch(const HomeLinesPointReached());

    await plain.dispatch(HomeLinesEvaluated(_facts()));

    expect(plain.state.install, isFalse);
  });
}
