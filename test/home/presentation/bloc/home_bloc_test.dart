import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'dart:async';

import 'package:expense_tracker/home/presentation/bloc/home_bloc.dart';
import 'package:expense_tracker/home/presentation/bloc/home_event.dart';
import 'package:expense_tracker/home/presentation/bloc/home_state.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeCategoryRepository categories;
  late FakeHaptics haptics;
  late HomeBloc bloc;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
    final FakeClock clock = FakeClock(WorkedExample.now);
    bloc = HomeBloc(
      getCycleSummary: GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      postDueRecurring: PostDueRecurring(recurring: recurring, clock: clock),
      getDueSoonBill: GetDueSoonBill(recurring: recurring, clock: clock),
      ledger: ledger,
      recurring: recurring,
      categories: categories,
      deleteEntry: DeleteEntry(ledger: ledger),
      restoreEntry: RestoreEntry(ledger: ledger),
      deleteBill: DeleteBill(recurring: recurring),
      restoreBill: RestoreBill(recurring: recurring),
      haptics: haptics,
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  HomeReady ready() => bloc.state as HomeReady;

  group('HomeBloc load', () {
    test('starts loading', () => expect(bloc.state, const HomeLoading()));

    test('shows the worked example: ₹1,430 safe and today\'s three entries, newest first', () async {
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().summary.safeToday, Money.fromMajor(1430));
      expect(ready().todayEntries.map((Entry e) => e.id), <int>[6, 5, 4]);
      expect(ready().categories[1]?.key, 'food');
    });

    test('shows at most 5 of today\'s entries (FR-HO-4)', () async {
      for (int i = 0; i < 4; i++) {
        await ledger.add(EntryDraft(amount: Money.fromMajor(10), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      }
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todayEntries, hasLength(HomeBloc.todayListLimit));
    });

    test('keeps every Spent entry dated today for the hero\'s bites, oldest first, past the list\'s 5 (BR-6)', () async {
      for (int i = 0; i < 4; i++) {
        await ledger.add(EntryDraft(amount: Money.fromMajor(10), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      }
      await ledger.add(EntryDraft(amount: Money.fromMajor(500), kind: EntryKind.got, categoryId: 1, date: WorkedExample.today)).run();
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todaySpends.map((Entry e) => e.id), <int>[4, 5, 6, 1000, 1001, 1002, 1003]);
    });

    test('runs the recurring engine before working out today (BR-8)', () async {
      recurring.rules = <RecurringRule>[
        RecurringRule(
          id: 9,
          label: 'Milk',
          amount: Money.fromMajor(300),
          kind: EntryKind.spent,
          categoryId: 1,
          schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 26)),
          nextDue: WorkedExample.today,
        ),
      ];
      await bloc.dispatch(const HomeLoadRequested());
      expect(recurring.postings, hasLength(1));
    });

    test('still loads when the engine fails', () async {
      final FakeRecurringRepository broken = FakeRecurringRepository()..failure = DatabaseFailure('locked');
      final FakeClock clock = FakeClock(WorkedExample.now);
      final HomeBloc withBrokenEngine = HomeBloc(
        getCycleSummary: GetCycleSummary(
          ledger: ledger,
          recurring: recurring,
          settings: FakeBudgetSettingsRepository(),
          periods: const PeriodCalculator(),
          clock: clock,
        ),
        postDueRecurring: PostDueRecurring(recurring: broken, clock: clock),
        getDueSoonBill: GetDueSoonBill(recurring: recurring, clock: clock),
        ledger: ledger,
        recurring: recurring,
        categories: categories,
        deleteEntry: DeleteEntry(ledger: ledger),
        restoreEntry: RestoreEntry(ledger: ledger),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        haptics: haptics,
      );
      addTearDown(withBrokenEngine.close);
      await withBrokenEngine.dispatch(const HomeLoadRequested());
      expect(withBrokenEngine.state, isA<HomeReady>());
    });

    test('shows the soonest bill due within 5 days (FR-HO-3)', () async {
      await bloc.dispatch(const HomeLoadRequested());
      expect(
        ready().dueSoon,
        Option<DueSoonBill>.of(
          DueSoonBill(rule: WorkedExample.electricity, dueDate: const CalendarDate(2026, 10, 29), daysAway: 3),
        ),
      );
    });

    test('still loads, without the nudge, when bills can\'t be read for it', () async {
      final FakeClock clock = FakeClock(WorkedExample.now);
      final HomeBloc withBrokenNudge = HomeBloc(
        getCycleSummary: GetCycleSummary(
          ledger: ledger,
          recurring: recurring,
          settings: FakeBudgetSettingsRepository(),
          periods: const PeriodCalculator(),
          clock: clock,
        ),
        postDueRecurring: PostDueRecurring(recurring: recurring, clock: clock),
        getDueSoonBill: GetDueSoonBill(recurring: FakeRecurringRepository()..failure = DatabaseFailure('locked'), clock: clock),
        ledger: ledger,
        recurring: recurring,
        categories: categories,
        deleteEntry: DeleteEntry(ledger: ledger),
        restoreEntry: RestoreEntry(ledger: ledger),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        haptics: haptics,
      );
      addTearDown(withBrokenNudge.close);
      await withBrokenNudge.dispatch(const HomeLoadRequested());
      expect((withBrokenNudge.state as HomeReady).dueSoon, const Option<DueSoonBill>.none());
    });

    test('reloads after a bill is added, edited or deleted in Settings', () async {
      await bloc.dispatch(const HomeLoadRequested());
      final Future<void> reloaded = expectLater(
        bloc.stream,
        emitsThrough(isA<HomeReady>().having((HomeReady s) => s.dueSoon, 'dueSoon', const Option<DueSoonBill>.none())),
      );
      await recurring.setActive(WorkedExample.electricity.id, active: false).run();
      await reloaded;
    });

    test('emits HomeFailed when the summary can\'t be read', () async {
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(const HomeLoadRequested());
      expect(bloc.state, isA<HomeFailed>());
    });

    test('emits HomeFailed when categories can\'t be read', () async {
      categories.failure = DatabaseFailure('locked');
      await bloc.dispatch(const HomeLoadRequested());
      expect(bloc.state, isA<HomeFailed>());
    });

    test('reloads after any write to the ledger (BR-10)', () async {
      await bloc.dispatch(const HomeLoadRequested());
      final Future<void> reloaded = expectLater(
        bloc.stream,
        emitsThrough(isA<HomeReady>().having((HomeReady s) => s.summary.spentToday, 'spentToday', Money.fromMajor(520))),
      );
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await reloaded;
    });
  });

  group('HomeBloc while the Add tray covers Home (FR-AD-5, D91)', () {
    test('holds the numbers through a save, then reloads once the tray has closed', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeTrayOpened());
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();
      expect(ready().summary.spentToday, Money.fromMajor(420));

      await bloc.dispatch(const HomeTrayClosed());
      expect(ready().summary.spentToday, Money.fromMajor(520));
    });

    test('a tray closed without a save does not reload', () async {
      await bloc.dispatch(const HomeLoadRequested());
      final List<HomeState> emitted = <HomeState>[];
      final StreamSubscription<HomeState> listening = bloc.stream.listen(emitted.add);
      addTearDown(listening.cancel);

      await bloc.dispatch(const HomeTrayOpened());
      await bloc.dispatch(const HomeTrayClosed());
      expect(emitted, isEmpty);
    });

    test('several writes under the tray reload once', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeTrayOpened());
      for (int i = 0; i < 2; i++) {
        await ledger.add(EntryDraft(amount: Money.fromMajor(50), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      }
      final List<HomeState> emitted = <HomeState>[];
      final StreamSubscription<HomeState> listening = bloc.stream.listen(emitted.add);
      addTearDown(listening.cancel);

      await bloc.dispatch(const HomeTrayClosed());
      expect(emitted.map((HomeState s) => (s as HomeReady).summary.spentToday), <Money>[Money.fromMajor(520)]);
    });

    test('reloads on the next write once the tray has closed', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeTrayOpened());
      await bloc.dispatch(const HomeTrayClosed());
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();
      expect(ready().summary.spentToday, Money.fromMajor(520));
    });
  });

  group('HomeBloc delete and undo (BR-10)', () {
    setUp(() => bloc.dispatch(const HomeLoadRequested()));

    test('removes the row first, then offers Undo for it', () async {
      final Entry chai = ready().todayEntries.last;
      final Future<void> states = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<HomeReady>()
              .having((HomeReady s) => s.todayEntries, 'todayEntries', isNot(contains(chai)))
              .having((HomeReady s) => s.undo, 'undo', const Option<Entry>.none()),
          emitsThrough(isA<HomeReady>().having((HomeReady s) => s.undo, 'undo', Option<Entry>.of(chai))),
        ]),
      );
      await bloc.dispatch(HomeDeleteRequested(chai));
      await states;
    });

    test('undo puts the entry back', () async {
      final Entry chai = ready().todayEntries.last;
      await bloc.dispatch(HomeDeleteRequested(chai));
      await bloc.dispatch(HomeUndoRequested(chai));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todayEntries, contains(chai));
    });

    test('a failed delete reloads so the row comes back', () async {
      final Entry chai = ready().todayEntries.last;
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(HomeDeleteRequested(chai));
      expect(bloc.state, isA<HomeFailed>(), reason: 'the reload fails too while the database is locked');
    });

    test('a failed undo is quiet', () async {
      final Entry chai = ready().todayEntries.last;
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(HomeUndoRequested(chai));
      expect(ledger.entries, isNot(contains(isA<Entry>().having((Entry e) => e.id, 'id', 9999))));
    });

    test('delete does nothing before Home has loaded', () async {
      final HomeBloc fresh = HomeBloc(
        getCycleSummary: GetCycleSummary(
          ledger: ledger,
          recurring: recurring,
          settings: FakeBudgetSettingsRepository(),
          periods: const PeriodCalculator(),
          clock: FakeClock(WorkedExample.now),
        ),
        postDueRecurring: PostDueRecurring(recurring: recurring, clock: FakeClock(WorkedExample.now)),
        getDueSoonBill: GetDueSoonBill(recurring: recurring, clock: FakeClock(WorkedExample.now)),
        ledger: ledger,
        recurring: recurring,
        categories: categories,
        deleteEntry: DeleteEntry(ledger: ledger),
        restoreEntry: RestoreEntry(ledger: ledger),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        haptics: haptics,
      );
      addTearDown(fresh.close);
      await fresh.dispatch(HomeDeleteRequested(WorkedExample.entries.last));
      expect(ledger.entries, contains(WorkedExample.entries.last));
    });

    test('closing mid-delete does not throw', () async {
      bloc.add(HomeDeleteRequested(ready().todayEntries.last));
      await expectLater(bloc.close(), completes);
    });

    test('crossing the swipe threshold plays one light haptic', () async {
      await bloc.dispatch(const HomeSwipeThresholdReached());
      expect(haptics.events, <String>['threshold']);
    });
  });

  group('HomeBloc bill delete and undo from the bill sheet (FR-HO-3, D118)', () {
    setUp(() => bloc.dispatch(const HomeLoadRequested()));

    test('deletes the bill, offers Undo for it, and reloads without its nudge', () async {
      expect(ready().dueSoon.map((DueSoonBill b) => b.rule), Option<RecurringRule>.of(WorkedExample.electricity));
      final Future<void> states = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<HomeReady>().having((HomeReady s) => s.billUndo, 'billUndo', Option<RecurringRule>.of(WorkedExample.electricity)),
          emitsThrough(isA<HomeReady>().having((HomeReady s) => s.dueSoon, 'dueSoon', const Option<DueSoonBill>.none())),
        ]),
      );
      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.electricity));
      await states;
      expect(recurring.stopped, contains(WorkedExample.electricity));
      expect(ready().billUndo, const Option<RecurringRule>.none());
    });

    test('undo brings the bill back and its nudge with it', () async {
      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.electricity));
      await bloc.dispatch(HomeBillUndoRequested(WorkedExample.electricity));
      await pumpEventQueue();
      expect(recurring.rules, contains(WorkedExample.electricity));
      expect(ready().dueSoon.map((DueSoonBill b) => b.rule), Option<RecurringRule>.of(WorkedExample.electricity));
    });

    test('a failed delete offers no Undo', () async {
      recurring.failure = DatabaseFailure('locked');
      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.electricity));
      expect(ready().billUndo, const Option<RecurringRule>.none());
    });

    test('a failed undo is quiet', () async {
      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.electricity));
      recurring.failure = DatabaseFailure('locked');
      await bloc.dispatch(HomeBillUndoRequested(WorkedExample.electricity));
      expect(bloc.state, isA<HomeReady>());
    });
  });

  test('a bill delete does nothing before Home has loaded', () async {
    await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.electricity));
    expect(recurring.stopped, isEmpty);
  });

  group('HomeBloc week toggle (FR-HO-2)', () {
    test('starts on Today', () async {
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().showWeek, isFalse);
    });

    test('flips to This week and back, with a tick each time', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeWeekToggled());
      expect(ready().showWeek, isTrue);
      await bloc.dispatch(const HomeWeekToggled());
      expect(ready().showWeek, isFalse);
      expect(haptics.events, <String>['tick', 'tick']);
    });

    test('stays on This week when Home reloads', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeWeekToggled());
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().showWeek, isTrue);
    });

    test('stays on This week after a delete', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeWeekToggled());
      await bloc.dispatch(HomeDeleteRequested(ready().todayEntries.first));
      expect(ready().showWeek, isTrue);
    });

    test('does nothing before Home has loaded', () async {
      await bloc.dispatch(const HomeWeekToggled());
      expect(bloc.state, const HomeLoading());
      expect(haptics.events, isEmpty);
    });
  });

  test('carries yesterday\'s saving through to the summary (BR-8)', () async {
    await bloc.dispatch(const HomeLoadRequested());
    expect(ready().summary.savedYesterday.isSome(), isTrue);
  });

  test('closing mid-load does not throw', () async {
    bloc.add(const HomeLoadRequested());
    await expectLater(bloc.close(), completes);
  });

  test('a write during a slow load ends on the fresh numbers', () async {
    await bloc.dispatch(const HomeLoadRequested());
    final Completer<void> slowRead = Completer<void>();
    ledger.nextReadGate = slowRead;
    await bloc.dispatch(const HomeLoadRequested());
    await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
    await pumpEventQueue();
    slowRead.complete();
    await pumpEventQueue();
    expect(ready().summary.spentToday, Money.fromMajor(520));
  });

  test('events compare by their fields', () {
    expect(const HomeLoadRequested().props, isEmpty);
    expect(HomeDeleteRequested(WorkedExample.entries.last).props, <Object?>[WorkedExample.entries.last]);
    expect(HomeUndoRequested(WorkedExample.entries.last), HomeUndoRequested(WorkedExample.entries.last));
  });
}
