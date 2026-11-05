import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

const CalendarDate _oct20 = CalendarDate(2026, 10, 20);

RecurringRule _rule(AmountMode mode) => RecurringRule(
      id: 8,
      label: mode == AmountMode.card ? 'HDFC card' : 'Electricity',
      amount: Money.fromMajor(1200),
      kind: EntryKind.spent,
      categoryId: mode == AmountMode.card ? SeedCategoryIds.cardPaid : SeedCategoryIds.bills,
      schedule: const Schedule(frequency: Frequency.monthly, anchor: _oct20),
      nextDue: _oct20,
      amountMode: mode,
    );

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late EnterBillAmount enter;

  setUp(() {
    ledger = FakeLedgerRepository();
    recurring = FakeRecurringRepository(<RecurringRule>[_rule(AmountMode.varies), _rule(AmountMode.card)]);
    enter = EnterBillAmount(ledger: ledger, recurring: recurring);
  });

  tearDown(() => ledger.dispose());

  EnterBillAmountParams params(AmountMode mode, int rupees) =>
      EnterBillAmountParams(occurrence: Occurrence(rule: _rule(mode), date: _oct20), amount: Money.fromMajor(rupees));

  group('EnterBillAmount (D123)', () {
    test('a changing bill is entered as Spent on its date, linked to its rule', () async {
      final BillAmountEntered done = (await enter(params(AmountMode.varies, 1460)).run()).getOrElse((Failure f) => fail(f.message));
      expect(done.entry.kind, EntryKind.spent);
      expect(done.entry.date, _oct20);
      expect(done.entry.amount, Money.fromMajor(1460));
      expect(done.entry.recurringId, 8);
      expect(done.entry.categoryId, SeedCategoryIds.bills);
      expect(done.entry.note, isNull);
    });

    test('the amount becomes the next estimate, and the old rule is kept for Undo', () async {
      final BillAmountEntered done = (await enter(params(AmountMode.varies, 1460)).run()).getOrElse((Failure f) => fail(f.message));
      expect(recurring.updates.single.amount, Money.fromMajor(1460));
      expect(done.previous.amount, Money.fromMajor(1200));
    });

    test('a card bill is recorded as paid, named after the card', () async {
      final BillAmountEntered done = (await enter(params(AmountMode.card, 8000)).run()).getOrElse((Failure f) => fail(f.message));
      expect(done.entry.kind, EntryKind.cardPaid);
      expect(done.entry.note, 'HDFC card');
      expect(done.entry.categoryId, SeedCategoryIds.cardPaid);
    });

    test('₹0 is refused and nothing is written', () async {
      expect((await enter(params(AmountMode.varies, 0)).run()).getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(ledger.entries, isEmpty);
      expect(recurring.updates, isEmpty);
    });

    test('a failed estimate update still enters the bill', () async {
      recurring.failure = DatabaseFailure('disk');
      final BillAmountEntered done = (await enter(params(AmountMode.varies, 1460)).run()).getOrElse((Failure f) => fail(f.message));
      expect(ledger.entries.single, done.entry);
    });

    test('a failed entry write leaves the estimate alone', () async {
      ledger.failure = DatabaseFailure('disk');
      expect((await enter(params(AmountMode.varies, 1460)).run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect(recurring.updates, isEmpty);
    });
  });
}
