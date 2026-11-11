import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  final RecurringRule electricity = RecurringRule(
    id: 8,
    label: 'Electricity',
    amount: Money.fromMajor(1460),
    kind: EntryKind.spent,
    categoryId: 5,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 8, 20)),
    nextDue: const CalendarDate(2026, 8, 20),
    amountMode: AmountMode.varies,
  );

  Entry entry(int id, int rupees, CalendarDate date, {int? recurringId = 8}) => Entry(
        id: id,
        amount: Money.fromMajor(rupees),
        kind: EntryKind.spent,
        categoryId: 5,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 9),
        recurringId: recurringId,
      );

  Future<Option<Money>> lastOf(List<Entry> entries) async {
    final FakeLedgerRepository ledger = FakeLedgerRepository(entries);
    addTearDown(ledger.dispose);
    return (await GetLastBillAmount(ledger: ledger, clock: FakeClock(WorkedExample.now))(electricity).run())
        .getOrElse((Failure f) => fail(f.message));
  }

  group('GetLastBillAmount (D123)', () {
    test('the latest amount entered for this bill', () async {
      expect(
        await lastOf(<Entry>[entry(1, 1300, const CalendarDate(2026, 8, 20)), entry(2, 1460, const CalendarDate(2026, 9, 20))]),
        Option<Money>.of(Money.fromMajor(1460)),
      );
    });

    test('none when it was never entered, even if other bills were', () async {
      expect(await lastOf(<Entry>[entry(1, 900, const CalendarDate(2026, 9, 20), recurringId: 3), entry(2, 60, WorkedExample.today, recurringId: null)]),
          const Option<Money>.none());
    });

    test('finds an entry from before the bill\'s day was changed', () async {
      final FakeLedgerRepository ledger = FakeLedgerRepository(<Entry>[entry(1, 1300, const CalendarDate(2026, 9, 15))]);
      addTearDown(ledger.dispose);
      final RecurringRule moved = electricity.copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 20)),
      );
      expect(
        (await GetLastBillAmount(ledger: ledger, clock: FakeClock(WorkedExample.now))(moved).run()).getOrElse((Failure f) => fail(f.message)),
        Option<Money>.of(Money.fromMajor(1300)),
      );
    });

    test('a read failure is passed on', () async {
      final FakeLedgerRepository ledger = FakeLedgerRepository()..failure = DatabaseFailure('disk');
      addTearDown(ledger.dispose);
      expect((await GetLastBillAmount(ledger: ledger, clock: FakeClock(WorkedExample.now))(electricity).run()).isLeft(), isTrue);
    });
  });
}
