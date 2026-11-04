import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late GetBills getBills;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    getBills = GetBills(recurring: recurring);
  });

  group('GetBills by kind (D120)', () {
    test('lists only rules of the asked kind, soonest first', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      final List<RecurringRule> bills = (await getBills(EntryKind.spent).run()).getOrElse((Failure f) => fail('$f'));
      final List<RecurringRule> savings = (await getBills(EntryKind.saved).run()).getOrElse((Failure f) => fail('$f'));
      expect(bills, <RecurringRule>[WorkedExample.electricity, WorkedExample.rent]);
      expect(savings, <RecurringRule>[WorkedExample.rd]);
    });
  });

  group('GetBills (FR-SE-1)', () {
    test('lists the fixed bills, soonest first, without the salary', () async {
      final List<RecurringRule> bills = (await getBills(EntryKind.spent).run()).getOrElse((Failure f) => fail('$f'));
      expect(bills, <RecurringRule>[WorkedExample.electricity, WorkedExample.rent]);
    });

    test('leaves out recurring money coming in', () async {
      final RecurringRule pocketMoney = RecurringRule(
        id: 8,
        label: 'Pocket money',
        amount: Money.fromMajor(500),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.otherIncome,
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 25)),
        nextDue: const CalendarDate(2026, 11, 1),
      );
      recurring.rules = <RecurringRule>[...WorkedExample.rules, pocketMoney];
      final List<RecurringRule> bills = (await getBills(EntryKind.spent).run()).getOrElse((Failure f) => fail('$f'));
      expect(bills, isNot(contains(pocketMoney)));
    });

    test('bills due the same day keep their saved order', () async {
      final RecurringRule second = WorkedExample.rent.copyWith(nextDue: WorkedExample.electricity.nextDue);
      recurring.rules = <RecurringRule>[second, WorkedExample.electricity];
      final List<RecurringRule> bills = (await getBills(EntryKind.spent).run()).getOrElse((Failure f) => fail('$f'));
      expect(bills, <RecurringRule>[second, WorkedExample.electricity]);
    });

    test('is empty with no bills', () async {
      recurring.rules = <RecurringRule>[WorkedExample.salary];
      expect((await getBills(EntryKind.spent).run()).getOrElse((Failure f) => fail('$f')), isEmpty);
    });

    test('returns the repository failure', () async {
      recurring.failure = const InvalidDataFailure('boom');
      expect((await getBills(EntryKind.spent).run()).getLeft().toNullable(), const InvalidDataFailure('boom'));
    });
  });
}
