import 'package:expense_tracker/ask_ai/domain/entities/prompt_input.dart';
import 'package:expense_tracker/ask_ai/domain/usecase/get_prompt_input.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ask_ai/prompt_input.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));
const PayCycle _september = PayCycle(start: CalendarDate(2026, 9, 4), end: CalendarDate(2026, 10, 3));

Entry _entry(int id, CalendarDate date) => Entry(
  id: id,
  amount: Money.fromMajor(100),
  kind: EntryKind.spent,
  categoryId: SeedCategoryIds.food,
  date: date,
  createdAt: DateTime(date.year, date.month, date.day),
);

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeClock clock;
  late FakeBudgetSettingsRepository settings;

  GetPromptInput useCase() => GetPromptInput(
    ledger: ledger,
    recurring: recurring,
    settings: settings,
    categories: FakeCategoryRepository(),
    periods: const PeriodCalculator(),
    clock: clock,
  );

  Future<PromptInput> load(PayCycle cycle) async =>
      (await useCase()(cycle).run()).getOrElse((Failure f) => throw StateError('unexpected $f'));

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    clock = FakeClock(WorkedExample.now);
    settings = FakeBudgetSettingsRepository();
  });

  group('GetPromptInput (BR-15)', () {
    test('loads the shown cycle and the two before it', () async {
      expect((await load(_october)).cycles, workedCycles);
    });

    test('entries stop at today for the current cycle', () async {
      ledger.entries.add(_entry(30, const CalendarDate(2026, 10, 30)));
      final PromptInput input = await load(_october);
      expect(input.entries.map((Entry e) => e.id), unorderedEquals(<int>[1, 2, 3, 4, 5, 6]));
      expect(input.today, WorkedExample.today);
    });

    test('loads from the oldest cycle start', () async {
      ledger.entries.add(_entry(30, const CalendarDate(2026, 8, 4)));
      ledger.entries.add(_entry(31, const CalendarDate(2026, 8, 3)));
      final List<int> ids = (await load(_october)).entries.map((Entry e) => e.id).toList();
      expect(ids, contains(30));
      expect(ids, isNot(contains(31)));
    });

    test('a past cycle loads up to its own end', () async {
      ledger.entries.add(_entry(30, const CalendarDate(2026, 10, 3)));
      final PromptInput input = await load(_september);
      expect(input.cycles.map((PayCycle c) => c.start), <CalendarDate>[
        const CalendarDate(2026, 9, 4),
        const CalendarDate(2026, 8, 4),
        const CalendarDate(2026, 7, 4),
      ]);
      expect(input.entries.map((Entry e) => e.id), <int>[30]);
    });

    test('splits the income rule from the bills', () async {
      final PromptInput input = await load(_october);
      expect(input.incomeRule, Option<RecurringRule>.of(WorkedExample.salary));
      expect(input.bills, unorderedEquals(<RecurringRule>[WorkedExample.rent, WorkedExample.electricity]));
      expect(input.payRule, const MonthlyOnDay(4));
      expect(input.categories, seedCategories);
    });

    test('no income rule gives None and irregular pay', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      final PromptInput input = await load(const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)));
      expect(input.incomeRule, const Option<RecurringRule>.none());
      expect(input.payRule, const IrregularIncome());
      expect(input.cycles[1], const PayCycle(start: CalendarDate(2026, 9, 1), end: CalendarDate(2026, 9, 30)));
    });

    test('payday on the 31st crosses February (E1)', () async {
      recurring.rules = <RecurringRule>[
        WorkedExample.salary.copyWith(
          schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2027, 1, 31)),
        ),
      ];
      clock = FakeClock(DateTime(2027, 4, 10));
      final PromptInput input = await load(const PayCycle(start: CalendarDate(2027, 3, 31), end: CalendarDate(2027, 4, 29)));
      expect(input.cycles[1], const PayCycle(start: CalendarDate(2027, 2, 28), end: CalendarDate(2027, 3, 30)));
    });

    test("the current cycle carries Home's summary and the savings (D120)", () async {
      recurring.rules = <RecurringRule>[...recurring.rules, WorkedExample.rd];
      final PromptInput input = await load(_october);
      final CycleSummary home = (await GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: clock,
      )(const NoParams()).run()).getOrElse((Failure f) => throw StateError('unexpected $f'));
      expect(input.summary, Option<CycleSummary>.of(home));
      expect(input.savings, <RecurringRule>[WorkedExample.rd]);
    });

    test('a past cycle carries no summary', () async {
      expect((await load(_september)).summary, const Option<CycleSummary>.none());
    });

    test('passes a database failure through', () async {
      ledger.failure = DatabaseFailure('disk');
      expect((await useCase()(_october).run()).isLeft(), isTrue);
    });
  });
}
