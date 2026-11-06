import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/core/time/pay_switch.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late FakeCategoryRepository categories;
  late ChangePayRule change;
  const CalendarDate oct26 = CalendarDate(2026, 10, 26);

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    categories = FakeCategoryRepository();
    change = ChangePayRule(recurring: recurring, settings: settings, categories: categories, clock: FakeClock(WorkedExample.now));
  });

  Future<Either<Failure, Option<RecurringRule>>> run(PayRule to, {Option<RecurringRule>? from, int? monthly}) => change(
        ChangePayRuleParams(
          income: from ?? Option<RecurringRule>.of(WorkedExample.salary),
          to: to,
          monthly: Option<int>.fromNullable(monthly).map(Money.fromMajor),
          label: 'Money in',
        ),
      ).run();

  RecurringRule saved(Either<Failure, Option<RecurringRule>> result) =>
      result.getOrElse((Failure f) => fail('unexpected $f')).getOrElse(() => fail('expected a rule'));

  group('ChangePayRule (BR-1a, D140)', () {
    test('records the old rule and moves the salary to the new day, first paid on 25 Nov', () async {
      final RecurringRule rule = saved(await run(const MonthlyOnDay(25)));
      expect(settings.settings.paySwitches, const <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(4))]);
      expect(rule.schedule.anchor.day, 25);
      expect(rule.nextDue, const CalendarDate(2026, 11, 25));
      expect(rule.amount, Money.fromMajor(45000));
      expect(recurring.updates, <RecurringRule>[rule]);
    });

    test('a new payday of today is first paid next month, never today', () async {
      expect(saved(await run(const MonthlyOnDay(26))).nextDue, const CalendarDate(2026, 11, 26));
    });

    test('to the last day of the month', () async {
      final RecurringRule rule = saved(await run(const LastDayOfMonth()));
      expect(rule.schedule.lastDayOfMonth, isTrue);
      expect(rule.nextDue, const CalendarDate(2026, 10, 31));
    });

    test('monthly to weekly posts the month spread over the weeks (D26)', () async {
      final RecurringRule rule = saved(await run(const WeeklyOn(DateTime.friday)));
      expect(rule.schedule.frequency, Frequency.weekly);
      expect(rule.nextDue, const CalendarDate(2026, 10, 30));
      expect(rule.amount, Money.fromMajor(10384));
    });

    test('weekly back to monthly posts the month again', () async {
      final RecurringRule weekly = WorkedExample.salary.copyWith(
        amount: Money.fromMajor(10384),
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
        nextDue: const CalendarDate(2026, 10, 30),
      );
      recurring.rules = <RecurringRule>[weekly];
      expect(saved(await run(const MonthlyOnDay(1), from: Option<RecurringRule>.of(weekly))).amount, Money.fromMajor(44998));
    });

    test('to "It changes" stops the salary and keeps its past pay', () async {
      final Either<Failure, Option<RecurringRule>> result = await run(const IrregularIncome());
      expect(result.getOrElse((Failure f) => fail('unexpected $f')), const Option<RecurringRule>.none());
      expect(recurring.rules.where((RecurringRule r) => r.isIncomeSource), isEmpty);
      expect(settings.settings.paySwitches.single.from, const MonthlyOnDay(4));
    });

    test('from "It changes" adds a salary rule with the month typed, first paid on the new day', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      final RecurringRule rule = saved(await run(const MonthlyOnDay(1), from: const Option<RecurringRule>.none(), monthly: 30000));
      expect(rule.isIncomeSource, isTrue);
      expect(rule.label, 'Money in');
      expect(rule.kind, EntryKind.got);
      expect(rule.categoryId, SeedCategoryIds.salary);
      expect(rule.amount, Money.fromMajor(30000));
      expect(rule.nextDue, const CalendarDate(2026, 11, 1));
      expect(settings.settings.paySwitches.single.from, const IrregularIncome());
    });

    test('from "It changes" without an amount is refused and nothing is written', () async {
      final Either<Failure, Option<RecurringRule>> result = await run(const MonthlyOnDay(1), from: const Option<RecurringRule>.none());
      expect(result.getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(settings.settings.paySwitches, isEmpty);
    });

    test('from "It changes" with ₹0 is refused', () async {
      final Either<Failure, Option<RecurringRule>> result =
          await run(const MonthlyOnDay(1), from: const Option<RecurringRule>.none(), monthly: 0);
      expect(result.getLeft().toNullable(), isA<InvalidAmountFailure>());
    });

    test('the same rule writes nothing', () async {
      expect(saved(await run(const MonthlyOnDay(4))), WorkedExample.salary);
      expect(settings.settings.paySwitches, isEmpty);
      expect(recurring.updates, isEmpty);
    });

    test('"It changes" to "It changes" writes nothing', () async {
      final Either<Failure, Option<RecurringRule>> result = await run(const IrregularIncome(), from: const Option<RecurringRule>.none());
      expect(result.getOrElse((Failure f) => fail('unexpected $f')), const Option<RecurringRule>.none());
      expect(settings.settings.paySwitches, isEmpty);
    });

    test('a failed switch write changes no rule', () async {
      settings.switchFailure = DatabaseFailure('boom');
      expect((await run(const MonthlyOnDay(25))).getLeft().toNullable(), isA<DatabaseFailure>());
      expect(recurring.updates, isEmpty);
    });

    test('passes a rule failure through', () async {
      recurring.failure = DatabaseFailure('boom');
      expect((await run(const MonthlyOnDay(25))).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('passes a category failure through', () async {
      categories.failure = DatabaseFailure('boom');
      recurring.rules = <RecurringRule>[];
      expect(
        (await run(const MonthlyOnDay(1), from: const Option<RecurringRule>.none(), monthly: 30000)).getLeft().toNullable(),
        isA<DatabaseFailure>(),
      );
    });

    test('params compare by their fields', () {
      ChangePayRuleParams params() => ChangePayRuleParams(
            income: const Option<RecurringRule>.none(),
            to: const MonthlyOnDay(1),
            monthly: const Option<Money>.none(),
            label: 'Money in',
          );
      expect(params(), params());
    });
  });
}
