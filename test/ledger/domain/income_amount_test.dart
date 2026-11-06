import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  final RecurringRule weekly = WorkedExample.salary.copyWith(
    amount: Money.fromMajor(10384),
    schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
  );

  group('IncomeAmount.perPay', () {
    test('a monthly rule posts the monthly amount', () {
      expect(IncomeAmount.perPay(Money.fromMajor(50000), WorkedExample.salary.schedule), Money.fromMajor(50000));
    });

    test('a weekly rule posts the month spread over 52 weeks, floored to the rupee (D26)', () {
      expect(IncomeAmount.perPay(Money.fromMajor(45000), weekly.schedule), Money.fromMajor(10384));
    });

    test('₹1 a month is ₹0 a week', () {
      expect(IncomeAmount.perPay(Money.fromMajor(1), weekly.schedule), Money.fromMajor(0));
    });
  });

  group('IncomeAmount.monthlyOf', () {
    test('a monthly rule shows its own amount', () {
      expect(IncomeAmount.monthlyOf(WorkedExample.salary), Money.fromMajor(45000));
    });

    test('a weekly rule shows the smallest month that posts the same week', () {
      final Money monthly = IncomeAmount.monthlyOf(weekly);
      expect(monthly, Money.fromMajor(44998));
      expect(IncomeAmount.perPay(monthly, weekly.schedule), weekly.amount);
    });

    test('a ₹0 weekly rule shows ₹0', () {
      expect(IncomeAmount.monthlyOf(weekly.copyWith(amount: Money.fromMajor(0))), Money.fromMajor(0));
    });
  });
}
