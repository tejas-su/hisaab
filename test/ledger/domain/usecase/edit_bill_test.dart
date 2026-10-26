import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late EditBill editBill;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    editBill = EditBill(recurring: recurring, clock: FakeClock(WorkedExample.now));
  });

  EditBillParams params(RecurringRule rule, {String? label, int? rupees, required int day}) => EditBillParams(
        rule: rule,
        input: BillInput(label: label ?? rule.label, amount: rupees == null ? rule.amount : Money.fromMajor(rupees), dueDay: day),
      );

  Future<RecurringRule> edited(EditBillParams p) async =>
      (await editBill(p).run()).getOrElse((Failure f) => fail('unexpected $f'));

  group('EditBill (FR-SE-1; BR-9 edits change future occurrences only)', () {
    test('a new name and amount keep the rule, its category and its next date', () async {
      final RecurringRule rule = await edited(params(WorkedExample.electricity, label: 'Power', rupees: 1500, day: 29));
      expect(rule.id, WorkedExample.electricity.id);
      expect(rule.categoryId, WorkedExample.electricity.categoryId);
      expect((rule.label, rule.amount, rule.nextDue), ('Power', Money.fromMajor(1500), const CalendarDate(2026, 10, 29)));
      expect(recurring.rules.last, rule);
    });

    test('moving an unposted bill a day earlier moves its next date', () async {
      expect((await edited(params(WorkedExample.electricity, day: 28))).nextDue, const CalendarDate(2026, 10, 28));
    });

    test('a bill already posted this month moves within next month, never posting twice', () async {
      expect((await edited(params(WorkedExample.rent, day: 29))).nextDue, const CalendarDate(2026, 11, 29));
    });

    test('a day already past this month first goes out next month', () async {
      expect((await edited(params(WorkedExample.electricity, day: 2))).nextDue, const CalendarDate(2026, 11, 2));
    });

    test('moving an unposted bill to today posts it today', () async {
      expect((await edited(params(WorkedExample.electricity, day: 26))).nextDue, WorkedExample.today);
    });

    test('a stale next date from a missed run is never back-posted', () async {
      final RecurringRule stale = WorkedExample.electricity.copyWith(nextDue: const CalendarDate(2026, 9, 29));
      recurring.rules = <RecurringRule>[stale];
      expect((await edited(params(stale, day: 30))).nextDue, const CalendarDate(2026, 10, 30));
    });

    test('the schedule follows the new day', () async {
      expect((await edited(params(WorkedExample.rent, day: 31))).schedule.anchor.day, 31);
    });

    test('an invalid edit is refused before anything is saved', () async {
      expect((await editBill(params(WorkedExample.rent, rupees: 0, day: 5)).run()).getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(recurring.rules, WorkedExample.rules);
    });

    test('returns RuleNotFoundFailure for a rule that was deleted', () async {
      recurring.rules = <RecurringRule>[WorkedExample.salary];
      expect((await editBill(params(WorkedExample.rent, day: 5)).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });
  });
}
