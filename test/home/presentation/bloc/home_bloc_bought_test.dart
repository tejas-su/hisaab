import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
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
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// *I bought it* from a saving's sheet opened on Home: one Undo restores the saving and the money
/// (AC-T9, E152).
void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late HomeBloc bloc;

  Entry used() => Entry(
        id: 900,
        amount: Money.fromMajor(12000),
        kind: EntryKind.used,
        categoryId: SeedCategoryIds.saved,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        note: 'Insurance',
        savingId: 5,
      );

  UsedOutcome outcome() => UsedOutcome(entry: used(), saving: WorkedExample.insurance);

  setUp(() async {
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns, used()]);
    recurring = FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, WorkedExample.insurance]);
    await recurring.setActive(5, active: false).run();
    final FakeClock clock = FakeClock(WorkedExample.now);
    bloc = HomeBloc(
      getCycleSummary: GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      postDueRecurring: PostDueRecurring(recurring: recurring, ledger: ledger, clock: clock),
      getDueSoonBill: GetDueSoonBill(recurring: recurring, ledger: ledger, clock: clock),
      ledger: ledger,
      recurring: recurring,
      categories: FakeCategoryRepository(),
      deleteEntry: DeleteEntry(ledger: ledger),
      restoreEntry: RestoreEntry(ledger: ledger),
      deleteBill: DeleteBill(recurring: recurring),
      restoreBill: RestoreBill(recurring: recurring),
      undoBillAmount: UndoBillAmount(ledger: ledger, recurring: recurring),
      unskipBill: UnskipBillOccurrence(recurring: recurring),
      haptics: FakeHaptics(),
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
    await recurring.dispose();
  });

  HomeReady ready() => bloc.state as HomeReady;

  test('HomeBoughtDone before the first load waits and shows once on the first good load', () async {
    await bloc.dispatch(HomeBoughtDone(outcome()));
    expect(bloc.state, isA<HomeLoading>());

    await bloc.dispatch(const HomeLoadRequested());
    expect(ready().boughtUndo, Option<UsedOutcome>.of(outcome()));

    await bloc.dispatch(const HomeLoadRequested());
    expect(ready().boughtUndo, const Option<UsedOutcome>.none());
  });

  test('HomeBoughtDone on a loaded Home offers Undo once', () async {
    await bloc.dispatch(const HomeLoadRequested());

    await bloc.dispatch(HomeBoughtDone(outcome()));

    expect(ready().boughtUndo, Option<UsedOutcome>.of(outcome()));
  });

  test('Undo brings the saving back and deletes the Used entry', () async {
    await bloc.dispatch(const HomeLoadRequested());

    await bloc.dispatch(HomeBoughtUndoRequested(outcome()));

    expect(recurring.rules.map((RecurringRule r) => r.id), contains(5));
    expect(ledger.entries.where((Entry e) => e.id == 900), isEmpty);
  });

  test('a failed restore deletes nothing and is quiet', () async {
    await bloc.dispatch(const HomeLoadRequested());
    recurring.failure = DatabaseFailure('recurring');

    await bloc.dispatch(HomeBoughtUndoRequested(outcome()));

    expect(ledger.entries.where((Entry e) => e.id == 900), hasLength(1));
    expect(bloc.state, isA<HomeReady>());
  });

  test('I bought it on a reached saving with a put-in still due this cycle leaves the hero where it was (AC-T9)', () async {
    final RecurringRule reached = RecurringRule(
      id: 8,
      label: 'Phone',
      amount: Money.fromMajor(1000),
      kind: EntryKind.saved,
      categoryId: SeedCategoryIds.saved,
      schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 30)),
      nextDue: const CalendarDate(2026, 10, 30),
      target: Option<Money>.of(Money.fromMajor(12000)),
    );
    recurring.rules.add(reached);
    ledger.entries.add(
      Entry(
        id: 901,
        amount: Money.fromMajor(12000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 9, 30),
        createdAt: DateTime(2026, 9, 30, 12),
        recurringId: 8,
      ),
    );
    await bloc.dispatch(const HomeLoadRequested());
    final Money before = ready().summary.todayShare;

    await recurring.setActive(8, active: false).run();
    await bloc.dispatch(const HomeLoadRequested());

    expect(ready().summary.todayShare, before);
  });

  test('the events compare by their fields', () {
    expect(HomeBoughtDone(outcome()).props, <Object?>[outcome()]);
    expect(HomeBoughtUndoRequested(outcome()).props, <Object?>[outcome()]);
  });
}
