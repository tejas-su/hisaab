import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';

void main() {
  final RecurringRule electricity = RecurringRule(
    id: 8,
    label: 'Electricity',
    amount: Money.fromMajor(1200),
    kind: EntryKind.spent,
    categoryId: 5,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 20)),
    nextDue: const CalendarDate(2026, 10, 20),
    amountMode: AmountMode.varies,
  );

  test('Undo deletes the entry and puts the estimate back (E-e)', () async {
    final FakeLedgerRepository ledger = FakeLedgerRepository();
    addTearDown(ledger.dispose);
    final FakeRecurringRepository recurring = FakeRecurringRepository(<RecurringRule>[electricity]);
    final BillAmountEntered done = (await EnterBillAmount(ledger: ledger, recurring: recurring)(
      EnterBillAmountParams(occurrence: Occurrence(rule: electricity, date: const CalendarDate(2026, 10, 20)), amount: Money.fromMajor(1460)),
    ).run())
        .getOrElse((Failure f) => fail(f.message));

    expect(await UndoBillAmount(ledger: ledger, recurring: recurring)(done).run(), Either<Failure, Unit>.right(unit));
    expect(ledger.entries, isEmpty);
    expect(recurring.rules.single, electricity);
  });

  test('a failed delete leaves the estimate as entered', () async {
    final FakeLedgerRepository ledger = FakeLedgerRepository();
    addTearDown(ledger.dispose);
    final FakeRecurringRepository recurring = FakeRecurringRepository(<RecurringRule>[electricity.copyWith(amount: Money.fromMajor(1460))]);
    ledger.failure = DatabaseFailure('disk');
    final BillAmountEntered done = BillAmountEntered(
      entry: Entry(
        id: 1,
        amount: Money.fromMajor(1460),
        kind: EntryKind.spent,
        categoryId: 5,
        date: const CalendarDate(2026, 10, 20),
        createdAt: DateTime(2026, 10, 26),
        recurringId: 8,
      ),
      previous: electricity,
    );
    expect((await UndoBillAmount(ledger: ledger, recurring: recurring)(done).run()).isLeft(), isTrue);
    expect(recurring.updates, isEmpty);
  });

  test('Undo after the entry was swiped away still puts the estimate back', () async {
    final FakeLedgerRepository ledger = FakeLedgerRepository();
    addTearDown(ledger.dispose);
    final FakeRecurringRepository recurring = FakeRecurringRepository(<RecurringRule>[electricity]);
    final BillAmountEntered done = (await EnterBillAmount(ledger: ledger, recurring: recurring)(
      EnterBillAmountParams(occurrence: Occurrence(rule: electricity, date: const CalendarDate(2026, 10, 20)), amount: Money.fromMajor(1460)),
    ).run())
        .getOrElse((Failure f) => fail(f.message));
    await DeleteEntry(ledger: ledger)(done.entry.id).run();

    expect(await UndoBillAmount(ledger: ledger, recurring: recurring)(done).run(), Either<Failure, Unit>.right(unit));
    expect(recurring.rules.single, electricity);
  });
}
