import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/home/presentation/cubit/home_cubit.dart';
import 'package:expense_tracker/home/presentation/cubit/home_state.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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
  late HomeCubit cubit;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
    final FakeClock clock = FakeClock(WorkedExample.now);
    cubit = HomeCubit(
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
      haptics: haptics,
    );
  });

  tearDown(() async {
    await cubit.close();
    await ledger.dispose();
  });

  HomeReady ready() => cubit.state as HomeReady;

  group('HomeCubit.load', () {
    test('starts loading', () => expect(cubit.state, const HomeLoading()));

    test('shows the worked example: ₹1,430 safe and today\'s three entries, newest first', () async {
      await cubit.load();
      expect(ready().summary.safeToday, Money.fromMajor(1430));
      expect(ready().todayEntries.map((Entry e) => e.id), <int>[6, 5, 4]);
      expect(ready().categories[1]?.key, 'food');
    });

    test('shows at most 5 of today\'s entries (FR-HO-4)', () async {
      for (int i = 0; i < 4; i++) {
        await ledger.add(EntryDraft(amount: Money.fromMajor(10), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      }
      await cubit.load();
      expect(ready().todayEntries, hasLength(HomeCubit.todayListLimit));
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
      await cubit.load();
      expect(recurring.postings, hasLength(1));
    });

    test('still loads when the engine fails', () async {
      final FakeRecurringRepository broken = FakeRecurringRepository()..failure = DatabaseFailure('locked');
      final FakeClock clock = FakeClock(WorkedExample.now);
      final HomeCubit withBrokenEngine = HomeCubit(
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
        haptics: haptics,
      );
      addTearDown(withBrokenEngine.close);
      await withBrokenEngine.load();
      expect(withBrokenEngine.state, isA<HomeReady>());
    });

    test('shows the soonest bill due within 5 days (FR-HO-3)', () async {
      await cubit.load();
      expect(
        ready().dueSoon,
        Option<DueSoonBill>.of(
          DueSoonBill(label: 'Electricity', amount: Money.fromMajor(1200), dueDate: const CalendarDate(2026, 10, 29), daysAway: 3),
        ),
      );
    });

    test('still loads, without the nudge, when bills can\'t be read for it', () async {
      final FakeClock clock = FakeClock(WorkedExample.now);
      final HomeCubit withBrokenNudge = HomeCubit(
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
        haptics: haptics,
      );
      addTearDown(withBrokenNudge.close);
      await withBrokenNudge.load();
      expect((withBrokenNudge.state as HomeReady).dueSoon, const Option<DueSoonBill>.none());
    });

    test('reloads after a bill is added, edited or deleted in Settings', () async {
      await cubit.load();
      final Future<void> reloaded = expectLater(
        cubit.stream,
        emitsThrough(isA<HomeReady>().having((HomeReady s) => s.dueSoon, 'dueSoon', const Option<DueSoonBill>.none())),
      );
      await recurring.setActive(WorkedExample.electricity.id, active: false).run();
      await reloaded;
    });

    test('emits HomeFailed when the summary can\'t be read', () async {
      ledger.failure = DatabaseFailure('locked');
      await cubit.load();
      expect(cubit.state, isA<HomeFailed>());
    });

    test('emits HomeFailed when categories can\'t be read', () async {
      categories.failure = DatabaseFailure('locked');
      await cubit.load();
      expect(cubit.state, isA<HomeFailed>());
    });

    test('reloads after any write to the ledger (BR-10)', () async {
      await cubit.load();
      final Future<void> reloaded = expectLater(
        cubit.stream,
        emitsThrough(isA<HomeReady>().having((HomeReady s) => s.summary.spentToday, 'spentToday', Money.fromMajor(520))),
      );
      await ledger.add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await reloaded;
    });
  });

  group('HomeCubit delete and undo (BR-10)', () {
    setUp(() => cubit.load());

    test('removes the row at once, then offers Undo for it', () async {
      final Entry chai = ready().todayEntries.last;
      final Future<void> undoOffered = expectLater(
        cubit.stream,
        emitsThrough(isA<HomeReady>().having((HomeReady s) => s.undo, 'undo', Option<Entry>.of(chai))),
      );
      final Future<void> deleting = cubit.delete(chai);
      expect(ready().todayEntries, isNot(contains(chai)), reason: 'Dismissible needs the row gone synchronously');
      await deleting;
      await undoOffered;
    });

    test('undo puts the entry back', () async {
      final Entry chai = ready().todayEntries.last;
      await cubit.delete(chai);
      await cubit.undo(chai);
      await cubit.load();
      expect(ready().todayEntries, contains(chai));
    });

    test('a failed delete reloads so the row comes back', () async {
      final Entry chai = ready().todayEntries.last;
      ledger.failure = DatabaseFailure('locked');
      await cubit.delete(chai);
      expect(cubit.state, isA<HomeFailed>(), reason: 'the reload fails too while the database is locked');
    });

    test('a failed undo is quiet', () async {
      final Entry chai = ready().todayEntries.last;
      ledger.failure = DatabaseFailure('locked');
      await cubit.undo(chai);
      expect(ledger.entries, isNot(contains(isA<Entry>().having((Entry e) => e.id, 'id', 9999))));
    });

    test('delete does nothing before Home has loaded', () async {
      final HomeCubit fresh = HomeCubit(
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
        haptics: haptics,
      );
      addTearDown(fresh.close);
      await fresh.delete(WorkedExample.entries.last);
      expect(ledger.entries, contains(WorkedExample.entries.last));
    });

    test('closing mid-delete does not throw', () async {
      final Future<void> deleting = cubit.delete(ready().todayEntries.last);
      await cubit.close();
      await expectLater(deleting, completes);
    });

    test('crossing the swipe threshold plays one light haptic', () {
      cubit.swipeThresholdReached();
      expect(haptics.events, <String>['threshold']);
    });
  });

  test('closing mid-load does not throw', () async {
    final Future<void> loading = cubit.load();
    await cubit.close();
    await expectLater(loading, completes);
  });
}
