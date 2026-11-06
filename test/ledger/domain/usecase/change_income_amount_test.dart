import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/money/amount_input.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late ChangeIncomeAmount change;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    change = ChangeIncomeAmount(recurring: recurring);
  });

  Future<Either<Failure, RecurringRule>> run(RecurringRule rule, int rupees) =>
      change(ChangeIncomeAmountParams(rule: rule, monthly: Money.fromMajor(rupees))).run();

  group('ChangeIncomeAmount', () {
    test('changes only the amount, so this cycle\'s pay and the next date stay (D137)', () async {
      final RecurringRule rule = (await run(WorkedExample.salary, 50000)).getOrElse((Failure f) => fail('unexpected $f'));
      expect(rule, WorkedExample.salary.copyWith(amount: Money.fromMajor(50000)));
      expect(rule.nextDue, const CalendarDate(2026, 11, 4));
      expect(recurring.updates, <RecurringRule>[rule]);
    });

    test('a weekly rule stores the weekly share of the month typed (D26)', () async {
      final RecurringRule weekly = WorkedExample.salary.copyWith(
        amount: Money.fromMajor(10384),
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
      );
      recurring.rules = <RecurringRule>[weekly];
      final RecurringRule rule = (await run(weekly, 52000)).getOrElse((Failure f) => fail('unexpected $f'));
      expect(rule.amount, Money.fromMajor(12000));
    });

    test('the same amount writes nothing', () async {
      expect(await run(WorkedExample.salary, 45000), Either<Failure, RecurringRule>.right(WorkedExample.salary));
      expect(recurring.updates, isEmpty);
    });

    test('₹0 is refused and nothing is written', () async {
      expect((await run(WorkedExample.salary, 0)).getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(recurring.updates, isEmpty);
    });

    test('the 9-digit cap is allowed', () async {
      final RecurringRule rule = (await run(WorkedExample.salary, AmountInput.maxRupees)).getOrElse((Failure f) => fail('unexpected $f'));
      expect(rule.amount, Money.fromMajor(AmountInput.maxRupees));
    });

    test('past the 9-digit cap is refused', () async {
      expect((await run(WorkedExample.salary, AmountInput.maxRupees + 1)).getLeft().toNullable(), isA<InvalidAmountFailure>());
    });

    test('a weekly month too small for ₹1 a week is refused', () async {
      final RecurringRule weekly = WorkedExample.salary.copyWith(
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
      );
      expect((await run(weekly, 4)).getLeft().toNullable(), isA<InvalidAmountFailure>());
    });

    test('passes a save failure through', () async {
      recurring.failure = DatabaseFailure('boom');
      expect(await run(WorkedExample.salary, 50000), Either<Failure, RecurringRule>.left(DatabaseFailure('boom')));
    });
  });

  test('params compare by their fields', () {
    expect(
      ChangeIncomeAmountParams(rule: WorkedExample.salary, monthly: Money.fromMajor(1)),
      ChangeIncomeAmountParams(rule: WorkedExample.salary, monthly: Money.fromMajor(1)),
    );
  });
}
