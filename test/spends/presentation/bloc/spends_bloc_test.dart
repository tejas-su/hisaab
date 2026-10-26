import 'dart:async';

import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/entities/insight.dart';
import 'package:expense_tracker/spends/domain/usecase/get_spends_overview.dart';
import 'package:expense_tracker/spends/presentation/bloc/spends_bloc.dart';
import 'package:expense_tracker/spends/presentation/bloc/spends_event.dart';
import 'package:expense_tracker/spends/presentation/bloc/spends_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeHaptics haptics;
  late SpendsBloc bloc;
  final LimitOffer offer = LimitOffer(limits: <int, Money>{SeedCategoryIds.food: Money.fromMajor(10000)});

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    final FakeRecurringRepository recurring = FakeRecurringRepository(WorkedExample.rules);
    final FakeBudgetSettingsRepository settings = FakeBudgetSettingsRepository();
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
    final FakeClock clock = FakeClock(WorkedExample.now);
    bloc = SpendsBloc(
      getOverview: GetSpendsOverview(
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
      applyLimits: ApplySuggestedLimits(categories: categories),
      ledger: ledger,
      haptics: haptics,
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  SpendsReady ready() => bloc.state as SpendsReady;

  // Something dated in September, so there is an earlier cycle to show.
  Future<void> addSeptember() =>
      ledger.add(EntryDraft(amount: Money.fromMajor(900), kind: EntryKind.spent, categoryId: 1, date: const CalendarDate(2026, 9, 20))).run();

  group('SpendsBloc (FR-SP-1)', () {
    test('starts loading', () => expect(bloc.state, const SpendsLoading()));

    test('load shows the current cycle', () async {
      await bloc.dispatch(const SpendsLoadRequested());
      expect(ready().overview.isCurrent, isTrue);
      expect(ready().overview.spent, Money.fromMajor(27570));
    });

    test('earlier shows the cycle before, with a tick, and later comes back', () async {
      await addSeptember();
      await bloc.dispatch(const SpendsLoadRequested());
      await bloc.dispatch(const SpendsEarlierPressed());
      expect(ready().overview.cyclesBack, 1);
      expect(ready().overview.spent, Money.fromMajor(900));
      await bloc.dispatch(const SpendsLaterPressed());
      expect(ready().overview.cyclesBack, 0);
      expect(haptics.events, <String>['tick', 'tick']);
    });

    test('earlier does nothing when there is no earlier cycle', () async {
      await bloc.dispatch(const SpendsLoadRequested());
      await bloc.dispatch(const SpendsEarlierPressed());
      expect(ready().overview.cyclesBack, 0);
      expect(haptics.events, isEmpty);
    });

    test('later does nothing on the current cycle', () async {
      await bloc.dispatch(const SpendsLoadRequested());
      await bloc.dispatch(const SpendsLaterPressed());
      expect(ready().overview.cyclesBack, 0);
      expect(haptics.events, isEmpty);
    });

    test('earlier and later do nothing before loading', () async {
      await bloc.dispatch(const SpendsEarlierPressed());
      await bloc.dispatch(const SpendsLaterPressed());
      expect(bloc.state, const SpendsLoading());
    });

    test('stays on the shown cycle when the ledger changes', () async {
      await addSeptember();
      await bloc.dispatch(const SpendsLoadRequested());
      await bloc.dispatch(const SpendsEarlierPressed());
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: const CalendarDate(2026, 9, 21))).run();
      await pumpEventQueue();
      expect(ready().overview.cyclesBack, 1);
      expect(ready().overview.spent, Money.fromMajor(1000));
    });

    test('emits SpendsFailed when loading fails', () async {
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(const SpendsLoadRequested());
      expect(bloc.state, isA<SpendsFailed>());
    });

    test('closing mid-load does not throw', () async {
      bloc.add(const SpendsLoadRequested());
      await expectLater(bloc.close(), completes);
    });

    test('a write during a slow load ends on the fresh numbers', () async {
      final Completer<void> slowRead = Completer<void>();
      ledger.nextReadGate = slowRead;
      bloc.add(const SpendsLoadRequested());
      await pumpEventQueue();
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();
      slowRead.complete();
      await pumpEventQueue();
      expect(ready().overview.spent, Money.fromMajor(27670));
    });
  });

  group('SpendsBloc limits (BR-12)', () {
    test('saves the offered limits once, with the success haptic', () async {
      await bloc.dispatch(const SpendsLoadRequested());
      bloc
        ..add(SpendsLimitsAccepted(offer))
        ..add(SpendsLimitsAccepted(offer));
      await pumpEventQueue();
      expect(categories.savedLimits, <Map<int, Money>>[offer.limits]);
      expect(haptics.events, <String>['success']);
      expect(ready().savingLimits, isFalse);
    });

    test('a failed save says so, with the reject haptic', () async {
      await bloc.dispatch(const SpendsLoadRequested());
      categories.failure = DatabaseFailure('locked');
      await bloc.dispatch(SpendsLimitsAccepted(offer));
      expect(ready().limitsFailed, isTrue);
      expect(haptics.events, <String>['reject']);
    });

    test('does nothing before loading', () async {
      await bloc.dispatch(SpendsLimitsAccepted(offer));
      expect(categories.savedLimits, isEmpty);
    });

    test('closing mid-save does not throw', () async {
      await bloc.dispatch(const SpendsLoadRequested());
      bloc.add(SpendsLimitsAccepted(offer));
      await expectLater(bloc.close(), completes);
    });
  });

  test('events compare by their fields', () {
    expect(const SpendsLoadRequested().props, isEmpty);
    expect(SpendsLimitsAccepted(offer).props, <Object?>[offer]);
  });
}
