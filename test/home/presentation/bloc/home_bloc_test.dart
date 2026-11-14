import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'dart:async';

import 'package:hisaab/home/presentation/bloc/home_bloc.dart';
import 'package:hisaab/home/presentation/bloc/home_event.dart';
import 'package:hisaab/home/presentation/bloc/home_state.dart';
import 'package:hisaab/ledger/ledger.dart';
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
      undoBillAmount: UndoBillAmount(ledger: ledger, recurring: recurring),
      unskipBill: UnskipBillOccurrence(recurring: recurring),
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

    test('todaySpends leaves out a bill posted today, which the Today list still shows (D119)', () async {
      ledger.entries.add(Entry(
        id: 50,
        amount: Money.fromMajor(1200),
        kind: EntryKind.spent,
        categoryId: 1,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        recurringId: WorkedExample.electricity.id,
      ));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todaySpends.map((Entry e) => e.id), <int>[4, 5, 6]);
      expect(ready().todayEntries.map((Entry e) => e.id), contains(50));
    });

    test('a saving today is listed but never a bite (D120)', () async {
      ledger.entries.add(Entry(
        id: 51,
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: 11,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        recurringId: WorkedExample.rd.id,
        note: 'RD',
      ));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todayEntries.map((Entry e) => e.id), contains(51));
      expect(ready().todaySpends.map((Entry e) => e.id), isNot(contains(51)));
      expect(ready().summary.spentToday, Money.fromMajor(420));
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
        undoBillAmount: UndoBillAmount(ledger: ledger, recurring: recurring),
        unskipBill: UnskipBillOccurrence(recurring: recurring),
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
        undoBillAmount: UndoBillAmount(ledger: ledger, recurring: recurring),
        unskipBill: UnskipBillOccurrence(recurring: recurring),
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

    test('names each bill by its rule, so a bill row can say which bill it is', () async {
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().billNames, <int, String>{1: 'Salary', 2: 'Rent', 3: 'Electricity'});
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
    test('isCovered is true while a tray or sheet holds Home, counting overlaps (missed-log AC-4)', () async {
      expect(bloc.isCovered, isFalse);

      await bloc.dispatch(const HomeTrayOpened());
      await bloc.dispatch(const HomeTrayOpened());
      await bloc.dispatch(const HomeTrayClosed());
      expect(bloc.isCovered, isTrue);

      await bloc.dispatch(const HomeTrayClosed());
      expect(bloc.isCovered, isFalse);
    });

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

  group('HomeBloc under overlapping holds (D91)', () {
    test('a reload waits until the last hold closes', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeTrayOpened());
      await bloc.dispatch(const HomeTrayOpened());
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();

      await bloc.dispatch(const HomeTrayClosed());
      await pumpEventQueue();
      expect(ready().summary.spentToday, Money.fromMajor(420));

      await bloc.dispatch(const HomeTrayClosed());
      expect(ready().summary.spentToday, Money.fromMajor(520));
    });

    test('a close with nothing held does not block the next reload', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeTrayClosed());
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
        undoBillAmount: UndoBillAmount(ledger: ledger, recurring: recurring),
        unskipBill: UnskipBillOccurrence(recurring: recurring),
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

  group('HomeBloc a waiting bill entered or skipped (D123)', () {
    const CalendarDate oct26 = CalendarDate(2026, 10, 26);
    final RecurringRule varies = WorkedExample.electricity.copyWith(
      amountMode: AmountMode.varies,
      schedule: const Schedule(frequency: Frequency.monthly, anchor: oct26),
      nextDue: oct26,
    );
    final Occurrence occurrence = Occurrence(rule: varies, date: oct26);

    setUp(() async {
      recurring.rules = <RecurringRule>[WorkedExample.salary, WorkedExample.rent, varies];
      await bloc.dispatch(const HomeLoadRequested());
    });

    // why: the write reloads Home through the change streams; in the app the sheet's exit
    // animation lets that land before the outcome arrives, so the tests wait for it too.
    Future<BillAmountOutcome> entered() async {
      final BillAmountEntered done = (await EnterBillAmount(ledger: ledger, recurring: recurring)(
        EnterBillAmountParams(occurrence: occurrence, amount: Money.fromMajor(1460)),
      ).run())
          .getOrElse((Failure f) => fail(f.message));
      await pumpEventQueue();
      return BillAmountWasEntered(done);
    }

    test('the waiting bill is on Home', () {
      expect(ready().summary.waitingBills, <Occurrence>[occurrence]);
    });

    test('an entered amount offers Undo once', () async {
      final BillAmountOutcome outcome = await entered();
      await bloc.dispatch(HomeBillAmountDone(outcome));
      expect(ready().amountUndo, Option<BillAmountOutcome>.of(outcome));
    });

    test('Undo after entering deletes the entry, restores the estimate, and the bill waits again (E-e)', () async {
      final BillAmountOutcome outcome = await entered();
      await pumpEventQueue();
      expect(ready().summary.waitingBills, isEmpty);
      await bloc.dispatch(HomeBillAmountUndoRequested(outcome));
      await pumpEventQueue();
      expect(ledger.entries.where((Entry e) => e.recurringId == varies.id), isEmpty);
      expect(recurring.rules.last.amount, Money.fromMajor(1200));
      expect(ready().summary.waitingBills, <Occurrence>[occurrence]);
    });

    test('Undo after skipping makes it wait again', () async {
      const BillSkip skip = BillSkip(ruleId: 3, date: oct26);
      await recurring.skip(skip).run();
      await pumpEventQueue();
      expect(ready().summary.waitingBills, isEmpty);
      await bloc.dispatch(HomeBillAmountUndoRequested(BillAmountWasSkipped(occurrence: occurrence, skip: skip)));
      await pumpEventQueue();
      expect(recurring.skips, isEmpty);
      expect(ready().summary.waitingBills, <Occurrence>[occurrence]);
    });

    test('a failed undo is quiet', () async {
      final BillAmountOutcome outcome = await entered();
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(HomeBillAmountUndoRequested(outcome));
      expect(bloc.state, isA<HomeReady>());
    });
  });

  test('an amount done before Home has loaded offers nothing', () async {
    await bloc.dispatch(HomeBillAmountDone(BillAmountWasSkipped(
      occurrence: Occurrence(rule: WorkedExample.electricity, date: WorkedExample.today),
      skip: const BillSkip(ruleId: 3, date: WorkedExample.today),
    )));
    expect(bloc.state, isA<HomeLoading>());
  });

  test('an amount done while Home has failed is offered once Home loads again, and only once', () async {
    final BillAmountWasSkipped skipped = BillAmountWasSkipped(
      occurrence: Occurrence(rule: WorkedExample.electricity, date: WorkedExample.today),
      skip: const BillSkip(ruleId: 3, date: WorkedExample.today),
    );
    ledger.failure = DatabaseFailure('locked');
    await bloc.dispatch(const HomeLoadRequested());
    await bloc.dispatch(HomeBillAmountDone(skipped));
    ledger.failure = null;
    await bloc.dispatch(const HomeLoadRequested());
    expect(ready().amountUndo, Option<BillAmountOutcome>.of(skipped));
    await bloc.dispatch(const HomeLoadRequested());
    expect(ready().amountUndo, const Option<BillAmountOutcome>.none());
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

  test('the bill amount events compare by their outcome (D123)', () {
    final BillAmountOutcome skipped = BillAmountWasSkipped(
      occurrence: Occurrence(rule: WorkedExample.electricity, date: WorkedExample.today),
      skip: const BillSkip(ruleId: 3, date: WorkedExample.today),
    );
    expect(HomeBillAmountDone(skipped).props, <Object?>[skipped]);
    expect(HomeBillAmountUndoRequested(skipped).props, <Object?>[skipped]);
  });
  group('HomeBloc a Used save (AC-Y9, AC-Y10, NFR-12)', () {
    Entry usedEntry() => Entry(
          id: 900,
          amount: Money.fromMajor(4000),
          kind: EntryKind.used,
          categoryId: 11,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          note: 'Insurance',
          savingId: 5,
        );

    UsedOutcome outcome() => UsedOutcome(entry: usedEntry(), saving: WorkedExample.insurance);

    test('HomeUsedDone before the first load waits and shows on the first good load', () async {
      await bloc.dispatch(HomeUsedDone(outcome()));
      expect(bloc.state, isA<HomeLoading>());

      await bloc.dispatch(const HomeLoadRequested());

      expect(ready().usedUndo, Option<UsedOutcome>.of(outcome()));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().usedUndo, const Option<UsedOutcome>.none());
    });

    test('HomeUsedDone on a loaded Home offers Undo once', () async {
      await bloc.dispatch(const HomeLoadRequested());

      await bloc.dispatch(HomeUsedDone(outcome()));

      expect(ready().usedUndo, Option<UsedOutcome>.of(outcome()));
    });

    test('HomeUsedUndoRequested deletes through DeleteEntry', () async {
      ledger.entries.add(usedEntry());
      await bloc.dispatch(const HomeLoadRequested());

      await bloc.dispatch(HomeUsedUndoRequested(usedEntry()));

      expect(ledger.entries.where((Entry e) => e.id == 900), isEmpty);
    });

    test('a failed Undo is quiet', () async {
      await bloc.dispatch(const HomeLoadRequested());

      await bloc.dispatch(HomeUsedUndoRequested(usedEntry()));

      expect(bloc.state, isA<HomeReady>());
    });

    test('two overlapping holds keep Home held until both have closed (E110)', () async {
      await bloc.dispatch(const HomeLoadRequested());
      await bloc.dispatch(const HomeTrayOpened());
      await bloc.dispatch(const HomeTrayOpened());
      ledger.entries.add(usedEntry());
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todayEntries.map((Entry e) => e.id), isNot(contains(900)));

      await bloc.dispatch(const HomeTrayClosed());
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().todayEntries.map((Entry e) => e.id), isNot(contains(900)));

      await bloc.dispatch(const HomeTrayClosed());
      await pumpEventQueue();

      expect(ready().todayEntries.map((Entry e) => e.id), contains(900));
    });

    test('deleting a saving with a put-in offers Undo that says what stays (AC-Y10)', () async {
      ledger.entries.addAll(WorkedExample.insurancePutIns);
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.insurance];
      await bloc.dispatch(const HomeLoadRequested());
      final Future<void> offered = expectLater(
        bloc.stream,
        emitsThrough(
          isA<HomeReady>()
              .having((HomeReady s) => s.billUndo, 'billUndo', Option<RecurringRule>.of(WorkedExample.insurance))
              .having((HomeReady s) => s.billUndoKeepsHistory, 'keeps history', isTrue),
        ),
      );

      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.insurance));

      await offered;
    });

    test('deleting a saving with no put-in does not', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.insurance];
      await bloc.dispatch(const HomeLoadRequested());
      final Future<void> offered = expectLater(
        bloc.stream,
        emitsThrough(
          isA<HomeReady>()
              .having((HomeReady s) => s.billUndo.isSome(), 'has Undo', isTrue)
              .having((HomeReady s) => s.billUndoKeepsHistory, 'keeps history', isFalse),
        ),
      );

      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.insurance));

      await offered;
    });

    test('deleting a bill never says what stays, and a failed read of the totals does not stop the delete', () async {
      await bloc.dispatch(const HomeLoadRequested());
      final Future<void> offered = expectLater(
        bloc.stream,
        emitsThrough(isA<HomeReady>().having((HomeReady s) => s.billUndo.isSome(), 'has Undo', isTrue).having((HomeReady s) => s.billUndoKeepsHistory, 'keeps history', isFalse)),
      );
      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.rent));
      await offered;

      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.insurance];
      await bloc.dispatch(const HomeLoadRequested());
      ledger.failure = DatabaseFailure('ledger');
      await bloc.dispatch(HomeBillDeleteRequested(WorkedExample.insurance));
      expect(recurring.stopped, contains(WorkedExample.insurance));
    });

    test('the new events compare by their fields', () {
      expect(HomeUsedDone(outcome()).props, <Object?>[outcome()]);
      expect(HomeUsedUndoRequested(usedEntry()).props, <Object?>[usedEntry()]);
    });
  });

  group('HomeBloc a Used entry today (BR-19, FR-HO-4)', () {
    test('is listed but is never a bite, and the hero does not move', () async {
      await bloc.dispatch(const HomeLoadRequested());
      final Money before = ready().summary.safeToday;
      ledger.entries.add(Entry(
        id: 52,
        amount: Money.fromMajor(4000),
        kind: EntryKind.used,
        categoryId: 11,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        note: 'Insurance',
        savingId: 5,
      ));

      await bloc.dispatch(const HomeLoadRequested());

      expect(ready().todayEntries.map((Entry e) => e.id), contains(52));
      expect(ready().todaySpends.map((Entry e) => e.id), isNot(contains(52)));
      expect(ready().summary.safeToday, before);
    });
  });

}
