import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/usecase/get_month_story.dart';
import 'package:hisaab/spends/domain/usecase/get_spends_overview.dart';
import 'package:hisaab/spends/presentation/bloc/month_story_bloc.dart';
import 'package:hisaab/spends/presentation/bloc/month_story_event.dart';
import 'package:hisaab/spends/presentation/bloc/month_story_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late MonthStoryBloc bloc;

  void dropSeptemberToNine() =>
      ledger.entries.removeWhere((Entry e) => SeptemberStory.september.contains(e.date) && e.id > 15);

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[...SeptemberStory.augustEntries(), ...SeptemberStory.septemberEntries()]);
    final FakeRecurringRepository recurring = FakeRecurringRepository(WorkedExample.rules);
    final FakeBudgetSettingsRepository settings = FakeBudgetSettingsRepository();
    final FakeCategoryRepository categories = FakeCategoryRepository();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 5, 10));
    bloc = MonthStoryBloc(
      getStory: GetMonthStory(
        overview: GetSpendsOverview(
          ledger: ledger,
          recurring: recurring,
          settings: settings,
          categories: categories,
          suggestLimits: GetSuggestedLimits(
            ledger: ledger,
            recurring: recurring,
            settings: settings,
            categories: categories,
            periods: const PeriodCalculator(),
            clock: clock,
          ),
          periods: const PeriodCalculator(),
          clock: clock,
        ),
      ),
      cyclesBack: 1,
    );
  });

  tearDown(() async {
    await bloc.close();
    ledger.dispose();
  });

  group('MonthStoryBloc (FR-SP-7)', () {
    test('starts loading', () {
      expect(bloc.state, const MonthStoryLoading());
    });

    test('emits Ready with September when the story loads', () async {
      final Future<void> expectation = expectLater(
        bloc.stream,
        emits(isA<MonthStoryReady>().having((MonthStoryReady s) => s.story.cycle, 'cycle', SeptemberStory.september)),
      );
      await bloc.dispatch(const MonthStoryLoadRequested());
      await expectation;
    });

    test('emits Gone when the cycle no longer has a story', () async {
      dropSeptemberToNine();
      await bloc.dispatch(const MonthStoryLoadRequested());
      expect(bloc.state, const MonthStoryGone());
    });

    test('emits Failed when a read fails', () async {
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(const MonthStoryLoadRequested());
      expect(bloc.state, isA<MonthStoryFailed>());
    });

    test('a newer load wins over a slower older one (restartable)', () async {
      final Completer<void> gate = Completer<void>();
      ledger.nextReadGate = gate;
      bloc.add(const MonthStoryLoadRequested());
      await pumpEventQueue();
      dropSeptemberToNine();
      await bloc.dispatch(const MonthStoryLoadRequested());
      gate.complete();
      await pumpEventQueue();
      expect(bloc.state, const MonthStoryGone());
    });

    test('closing mid-load does not throw', () async {
      bloc.add(const MonthStoryLoadRequested());
      await expectLater(bloc.close(), completes);
    });
  });
}
