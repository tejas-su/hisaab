import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/category_spend.dart';
import 'package:hisaab/spends/domain/entities/insight.dart';
import 'package:hisaab/spends/domain/entities/pace_series.dart';
import 'package:hisaab/spends/domain/entities/spends_overview.dart';
import 'package:hisaab/spends/domain/usecase/get_spends_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _september = PayCycle(start: CalendarDate(2026, 9, 4), end: CalendarDate(2026, 10, 3));

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late FakeCategoryRepository categories;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    categories = FakeCategoryRepository();
  });

  tearDown(() => ledger.dispose());

  void addEntry(int rupees, int categoryId, CalendarDate date, {EntryKind kind = EntryKind.spent, CalendarDate? loggedOn}) {
    final CalendarDate logged = loggedOn ?? date;
    ledger.entries.add(
      Entry(
        id: 100 + ledger.entries.length,
        amount: Money.fromMajor(rupees),
        kind: kind,
        categoryId: categoryId,
        date: date,
        createdAt: DateTime(logged.year, logged.month, logged.day, 9),
      ),
    );
  }

  GetSpendsOverview useCase() {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return GetSpendsOverview(
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
    );
  }

  Future<SpendsOverview> overview([int cyclesBack = 0]) async =>
      (await useCase()(cyclesBack).run()).getOrElse((Failure f) => fail(f.message));

  group('GetSpendsOverview (FR-SP)', () {
    test('worked example: ₹27,570 of ₹45,000 spent, below pace, rows biggest first', () async {
      final SpendsOverview result = await overview();
      expect(result.cycle, const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)));
      expect(result.isCurrent, isTrue);
      expect(result.isEmpty, isFalse);
      expect(result.spent, Money.fromMajor(27570));
      expect(result.budget, Money.fromMajor(45000));
      expect(result.pace.map((PaceSeries p) => p.verdict), const Option<PaceVerdict>.of(PaceVerdict.belowPace));
      expect(result.rows.map((CategorySpend r) => (r.category.key, r.spent.floorMajor, r.percent)), <(String, int, int)>[
        ('food', 19010, 69),
        ('home', 8200, 30),
        ('shopping', 240, 1),
        ('travel', 120, 0),
      ]);
    });

    test('the steady line steps up by rent on its day and by electricity still to come (D129)', () async {
      final PaceSeries pace = (await overview()).pace.getOrElse(() => fail('no pace'));
      // 26 Oct is day 22: rent ₹8,200 + 23/31 of the other ₹35,600; 29 Oct (day 25) adds ₹1,200.
      expect(pace.steadyThrough(22), Money.fromMajor(34612));
      expect(pace.steadyThrough(25), Money.fromMajor(9400 + 29858));
      expect(pace.steadyThrough(30), Money.fromMajor(45000));
    });

    test('the current cycle forecasts as Home does: about ₹9,300 spare (BR-7, D133)', () async {
      final PaceSeries pace = (await overview()).pace.getOrElse(() => fail('no pace'));
      expect(pace.forecast, Option<RangeForecast>.of(LastsTillPayday(Money.fromMajor(9300))));
    });

    test('a past cycle has no forecast (D133)', () async {
      ledger.entries.add(Entry(
        id: 61,
        amount: Money.fromMajor(30000),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.salary,
        date: _september.start,
        createdAt: DateTime(2026, 9, 4),
      ));
      final PaceSeries pace = (await overview(1)).pace.getOrElse(() => fail('no pace'));
      expect(pace.forecast, const Option<RangeForecast>.none());
    });

    test('a card bill still to come never steps the steady line (D123)', () async {
      recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        WorkedExample.rent,
        WorkedExample.electricity.copyWith(amountMode: AmountMode.card),
      ];
      final PaceSeries pace = (await overview()).pace.getOrElse(() => fail('no pace'));
      expect(pace.steadyThrough(25) - pace.steadyThrough(24), Money.fromMajor(1187));
    });

    test('a past cycle has no bills still to come', () async {
      ledger.entries.add(Entry(
        id: 60,
        amount: Money.fromMajor(30000),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.salary,
        date: _september.start,
        createdAt: DateTime(2026, 9, 4),
      ));
      final PaceSeries pace = (await overview(1)).pace.getOrElse(() => fail('no pace'));
      expect(pace.steadyThrough(24), Money.fromMajor(25000));
    });

    test('first cycle in use: nothing earlier to go back to, and nothing to compare', () async {
      final SpendsOverview result = await overview();
      expect(result.canGoBack, isFalse);
      expect(result.insights, isEmpty);
    });

    test('savings come off the budget and are counted apart (D120)', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      ledger.entries.add(Entry(
          id: 50,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 10),
          createdAt: WorkedExample.now,
          recurringId: 4,
          note: 'RD',
        ));
      final SpendsOverview result = await overview();
      expect((result.budget, result.saved, result.spent), (Money.fromMajor(40000), Money.fromMajor(5000), Money.fromMajor(27570)));
    });

    test('an RD still to come this cycle is reserved but not yet saved', () async {
      recurring.rules = <RecurringRule>[
        ...WorkedExample.rules,
        WorkedExample.rd.copyWith(
          schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 30)),
          nextDue: const CalendarDate(2026, 10, 30),
        ),
      ];
      final SpendsOverview result = await overview();
      expect((result.budget, result.saved), (Money.fromMajor(40000), Money.zero));
    });

    test('saves never reach the rows, the pace or the insights', () async {
      final SpendsOverview before = await overview();
      ledger.entries.add(Entry(
          id: 50,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 10),
          createdAt: WorkedExample.now,
          recurringId: 4,
          note: 'RD',
        ));
      final SpendsOverview after = await overview();
      expect(after.rows, before.rows);
      expect(after.insights, before.insights);
      expect(after.spent, before.spent);
      // why: the pace's spending line ignores saves; only its budget line moves, as budget does (D120).
      expect(after.pace.toNullable()?.spentByDay, before.pace.toNullable()?.spentByDay);
    });

    test('a card bill paid never reaches spent, saved, the rows, the pace or the insights (D123)', () async {
      final SpendsOverview before = await overview();
      ledger.entries.add(Entry(
          id: 51,
          amount: Money.fromMajor(8000),
          kind: EntryKind.cardPaid,
          categoryId: SeedCategoryIds.cardPaid,
          date: const CalendarDate(2026, 10, 20),
          createdAt: WorkedExample.now,
          recurringId: 9,
          note: 'Credit card',
        ));
      final SpendsOverview after = await overview();
      expect(after.rows, before.rows);
      expect(after.insights, before.insights);
      expect(after.spent, before.spent);
      expect(after.saved, before.saved);
      expect(after.pace, before.pace);
    });

    test('no income: no pace chart, rows still show', () async {
      ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      final SpendsOverview result = await overview();
      expect(result.pace, const Option<PaceSeries>.none());
      expect(result.rows, isNotEmpty);
    });

    test('one cycle back: September, seen to its last day, can go forward', () async {
      addEntry(45000, SeedCategoryIds.salary, _september.start, kind: EntryKind.got);
      addEntry(900, SeedCategoryIds.food, const CalendarDate(2026, 10, 3));
      final SpendsOverview result = await overview(1);
      expect(result.cycle, _september);
      expect(result.isCurrent, isFalse);
      expect(result.spent, Money.fromMajor(900));
      expect(result.pace.map((PaceSeries p) => p.spentByDay.length), const Option<int>.of(30));
    });

    test('an earlier cycle with entries can be gone back to', () async {
      addEntry(900, SeedCategoryIds.food, const CalendarDate(2026, 9, 20), loggedOn: WorkedExample.today);
      expect((await overview()).canGoBack, isTrue);
    });

    test('used since before the earlier cycle ended: it can be gone back to, even if empty', () async {
      addEntry(45000, SeedCategoryIds.salary, const CalendarDate(2026, 10, 4), kind: EntryKind.got, loggedOn: _september.end);
      expect((await overview()).canGoBack, isTrue);
    });

    test('a nothing-spent cycle is empty', () async {
      expect((await overview(2)).isEmpty, isTrue);
    });

    test('with a full September tracked, Food up on last month shows first, then the limit offer', () async {
      addEntry(45000, SeedCategoryIds.salary, _september.start, kind: EntryKind.got);
      addEntry(2000, SeedCategoryIds.food, const CalendarDate(2026, 9, 10));
      final SpendsOverview result = await overview();
      expect(result.insights.first, CategoryUp(categoryId: SeedCategoryIds.food, rise: Money.fromMajor(17010)));
      expect(result.insights.last, isA<LimitOffer>());
    });

    test('a past cycle never offers limits', () async {
      addEntry(45000, SeedCategoryIds.salary, _september.start, kind: EntryKind.got);
      addEntry(2000, SeedCategoryIds.food, const CalendarDate(2026, 9, 10));
      expect((await overview(1)).insights.whereType<LimitOffer>(), isEmpty);
    });

    test('at most 3 insights: the limit offer is the first to go', () async {
      addEntry(45000, SeedCategoryIds.salary, _september.start, kind: EntryKind.got);
      addEntry(2000, SeedCategoryIds.food, const CalendarDate(2026, 9, 10));
      for (final int day in <int>[4, 5, 11, 12]) {
        addEntry(100, SeedCategoryIds.travel, CalendarDate(2026, 10, day));
      }
      addEntry(10, 3, const CalendarDate(2026, 10, 6));
      addEntry(10, 3, const CalendarDate(2026, 10, 7));
      addEntry(5000, 3, const CalendarDate(2026, 10, 8));
      final SpendsOverview result = await overview();
      expect(result.insights.map((Insight i) => i.runtimeType), <Type>[CategoryUp, BiggestSpend, SteadiestCategory]);
    });

    final List<(String, void Function())> failures = <(String, void Function())>[
      ('settings', () => settings.failure = DatabaseFailure('settings')),
      ('rules', () => recurring.failure = DatabaseFailure('rules')),
      ('categories', () => categories.failure = DatabaseFailure('categories')),
      ('entries', () => ledger.failure = DatabaseFailure('entries')),
    ];
    for (final (String name, void Function() breakIt) in failures) {
      test('returns DatabaseFailure when reading $name fails', () async {
        breakIt();
        expect((await useCase()(0).run()).getLeft().toNullable(), isA<DatabaseFailure>());
      });
    }
  });
}
