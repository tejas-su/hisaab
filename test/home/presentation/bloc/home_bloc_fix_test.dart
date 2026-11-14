import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/home/presentation/bloc/home_bloc.dart';
import 'package:hisaab/home/presentation/bloc/home_event.dart';
import 'package:hisaab/home/presentation/bloc/home_state.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// Home's side of *Fix my number*: the Undo it offers, and a fix never being spending (BR-18, FR-FX-5).
void main() {
  late FakeLedgerRepository ledger;
  late FakeHaptics haptics;
  late HomeBloc bloc;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    final FakeRecurringRepository recurring = FakeRecurringRepository(WorkedExample.rules);
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
      categories: FakeCategoryRepository(),
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

  FixOutcome outcome() => FixOutcome(entry: notLogged(4200, WorkedExample.today), safeToday: Money.fromMajor(963));

  group('a fix in the Today list', () {
    test('is in the list, on top when posted now, but never a bite (BR-6, BR-18)', () async {
      ledger.entries.add(notLogged(4200, WorkedExample.today, id: 900));

      await bloc.dispatch(const HomeLoadRequested());

      expect(ready().todayEntries.first.isNotLogged, isTrue);
      expect(ready().todaySpends.any((Entry e) => e.isNotLogged), isFalse);
      expect(ready().todaySpends, hasLength(3));
      expect(ready().summary.safeToday, Money.fromMajor(963));
    });
  });

  group('HomeFixDone (FR-FX-5)', () {
    test('offers Undo once and fires success as the number rolls', () async {
      await bloc.dispatch(const HomeLoadRequested());
      haptics.events.clear();

      await bloc.dispatch(HomeFixDone(outcome()));

      expect(ready().fixUndo, Option<FixOutcome>.of(outcome()));
      expect(haptics.events, <String>['success']);
      await bloc.dispatch(const HomeWeekToggled());
      expect(ready().fixUndo, const Option<FixOutcome>.none());
    });

    test('before the first load it waits and shows on the first good load (D127)', () async {
      await bloc.dispatch(HomeFixDone(outcome()));
      expect(bloc.state, isA<HomeLoading>());

      await bloc.dispatch(const HomeLoadRequested());

      expect(ready().fixUndo, Option<FixOutcome>.of(outcome()));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().fixUndo, const Option<FixOutcome>.none());
    });
  });

  group('the fix row growing in (FR-FX-5 AC-2, C9)', () {
    test('the load that first lists the fix marks its row, and only that load', () async {
      final Entry fix = notLogged(4200, WorkedExample.today, id: 900);
      await bloc.dispatch(const HomeLoadRequested());
      ledger.entries.add(fix);

      await bloc.dispatch(HomeFixDone(FixOutcome(entry: fix, safeToday: Money.fromMajor(963))));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().justFixed, Option<int>.of(900));
      await bloc.dispatch(const HomeWeekToggled());
      expect(ready().justFixed, Option<int>.of(900));

      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().justFixed, const Option<int>.none());
    });
  });

  group('installDue (FR-HO-3, C1, E109)', () {
    final CalendarDate cycleStart = WorkedExample.today.addDays(-22);

    Entry payPostedOn(CalendarDate installDay) => Entry(
          id: 1,
          amount: Money.fromMajor(45000),
          kind: EntryKind.got,
          categoryId: 9,
          date: cycleStart,
          createdAt: DateTime(installDay.year, installDay.month, installDay.day, 9),
          recurringId: 1,
        );

    Future<HomeReady> loadWith(List<Entry> entries, {bool seen = false}) async {
      final FakeLedgerRepository book = FakeLedgerRepository(entries);
      final FakeBudgetSettingsRepository settings = FakeBudgetSettingsRepository()..installSeen = seen;
      final FakeRecurringRepository recurring = FakeRecurringRepository(WorkedExample.rules);
      final FakeClock clock = FakeClock(WorkedExample.now);
      final HomeBloc home = HomeBloc(
        getCycleSummary: GetCycleSummary(ledger: book, recurring: recurring, settings: settings, periods: const PeriodCalculator(), clock: clock),
        postDueRecurring: PostDueRecurring(recurring: recurring, clock: clock),
        getDueSoonBill: GetDueSoonBill(recurring: recurring, clock: clock),
        ledger: book,
        recurring: recurring,
        categories: FakeCategoryRepository(),
        deleteEntry: DeleteEntry(ledger: book),
        restoreEntry: RestoreEntry(ledger: book),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        undoBillAmount: UndoBillAmount(ledger: book, recurring: recurring),
        unskipBill: UnskipBillOccurrence(recurring: recurring),
        haptics: FakeHaptics(),
        settings: settings,
      );
      addTearDown(() async {
        await home.close();
        await book.dispose();
      });
      await home.dispatch(const HomeLoadRequested());
      return home.state as HomeReady;
    }

    test('is due for an install in the middle of the cycle, not yet seen', () async {
      expect((await loadWith(<Entry>[payPostedOn(WorkedExample.today)])).installDue, isTrue);
    });

    test('is not due when the install day is the cycle first day, or the flag says seen', () async {
      expect((await loadWith(<Entry>[payPostedOn(cycleStart)])).installDue, isFalse);
      expect((await loadWith(<Entry>[payPostedOn(WorkedExample.today)], seen: true)).installDue, isFalse);
    });

    test('is not due in a later cycle than the install', () async {
      expect((await loadWith(<Entry>[payPostedOn(cycleStart.addDays(-40))])).installDue, isFalse);
    });

    test('is not due with no entries, and a bloc built without settings never shows it', () async {
      expect((await loadWith(<Entry>[])).installDue, isFalse);
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().installDue, isFalse);
    });
  });

  group('HomeFixUndoRequested', () {
    test('deletes the entry and the number returns to ₹1,430 along the same path, with a tick', () async {
      final Entry fix = (await ledger.add(EntryDraft(
        amount: Money.fromMajor(4200),
        kind: EntryKind.spent,
        categoryId: FakeLedgerRepository.notLoggedCategoryId,
        date: WorkedExample.today,
      )).run())
          .getOrElse((_) => fail('add'));
      await bloc.dispatch(const HomeLoadRequested());
      expect(ready().summary.safeToday, Money.fromMajor(963));
      haptics.events.clear();

      await bloc.dispatch(HomeFixUndoRequested(fix));
      await bloc.dispatch(const HomeLoadRequested());

      expect(ledger.entries.any((Entry e) => e.isNotLogged), isFalse);
      expect(ready().summary.safeToday, Money.fromMajor(1430));
      expect(haptics.events, <String>['tick']);
    });
  });
}
