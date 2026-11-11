import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late GetBillStatus getStatus;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    final FakeClock clock = FakeClock(WorkedExample.now);
    getStatus = GetBillStatus(
      ledger: ledger,
      clock: clock,
      summary: GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: clock,
      ),
    );
  });

  Future<BillStatus> status(RecurringRule rule) async =>
      (await getStatus(rule).run()).getOrElse((Failure f) => fail('unexpected $f'));

  RecurringRule monthlyOn(int day, CalendarDate nextDue) => RecurringRule(
        id: 9,
        label: 'Bill',
        amount: WorkedExample.rent.amount,
        kind: EntryKind.spent,
        categoryId: WorkedExample.rent.categoryId,
        schedule: Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, day)),
        nextDue: nextDue,
      );

  Entry postedFor(RecurringRule rule, CalendarDate date) => WorkedExample.entries[1].copyWithFor(rule.id, date);

  group('GetBillStatus (SPEC BR-9 bill stamp, D118)', () {
    test('a bill 3 days away is due, with its next date', () async {
      final BillStatus result = await status(WorkedExample.electricity);
      expect(result.stamp, const BillStampDue(3));
      expect((result.nextDate, result.daysAway), (const CalendarDate(2026, 10, 29), 3));
    });

    test('a bill posted this month is counted on the date it was posted', () async {
      final BillStatus result = await status(WorkedExample.rent);
      expect(result.stamp, const BillStampCounted(CalendarDate(2026, 10, 5)));
      expect((result.nextDate, result.daysAway), (const CalendarDate(2026, 11, 5), 10));
    });

    test('a bill added after its day this month (D33) has no stamp', () async {
      ledger.entries.removeWhere((Entry e) => e.recurringId == WorkedExample.rent.id);
      expect((await status(WorkedExample.rent)).stamp, const BillStampNone());
    });

    test('another bill\'s entry never counts for this one', () async {
      final RecurringRule other = monthlyOn(4, const CalendarDate(2026, 11, 4)); // salary posted 10-04 with id 1
      expect((await status(other)).stamp, const BillStampNone());
    });

    test('a bill posted today is counted today, not due (Review Focus 2)', () async {
      final RecurringRule today = monthlyOn(26, const CalendarDate(2026, 11, 26));
      ledger.entries.add(postedFor(today, WorkedExample.today));
      expect((await status(today)).stamp, const BillStampCounted(WorkedExample.today));
    });

    test('6 days away is past the due-soon window, so it shows counted', () async {
      final RecurringRule first = monthlyOn(1, const CalendarDate(2026, 11, 1));
      ledger.entries.add(postedFor(first, const CalendarDate(2026, 10, 1)));
      final BillStatus result = await status(first);
      expect(result.daysAway, GetDueSoonBill.window + 1);
      expect(result.stamp, const BillStampCounted(CalendarDate(2026, 10, 1)));
    });

    test('exactly the window away is still due', () async {
      expect((await status(monthlyOn(31, const CalendarDate(2026, 10, 31)))).stamp, const BillStampDue(5));
    });

    test('an entry before the previous occurrence is not this month\'s', () async {
      ledger.entries
        ..removeWhere((Entry e) => e.recurringId == WorkedExample.rent.id)
        ..add(postedFor(WorkedExample.rent, const CalendarDate(2026, 10, 4)));
      expect((await status(WorkedExample.rent)).stamp, const BillStampNone());
    });

    test('returns the ledger failure', () async {
      ledger.failure = DatabaseFailure('closed');
      expect((await getStatus(WorkedExample.rent).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('GetBillStatus, a bill waiting for its amount (D123)', () {
    RecurringRule waiting(AmountMode mode, CalendarDate due) => WorkedExample.electricity.copyWith(
          amountMode: mode,
          schedule: Schedule(frequency: Frequency.monthly, anchor: due),
          nextDue: due,
        );
    void use(RecurringRule rule) => recurring.rules = <RecurringRule>[WorkedExample.salary, WorkedExample.rent, rule];

    test('a changing bill that went out today waits, dated today', () async {
      final RecurringRule bill = waiting(AmountMode.varies, WorkedExample.today);
      use(bill);
      final BillStatus result = await status(bill);
      expect(result.stamp, const BillStampWaiting(WorkedExample.today));
      expect((result.nextDate, result.daysAway), (WorkedExample.today, 0));
    });

    test('a card bill from an earlier day waits, dated that day', () async {
      final RecurringRule card = waiting(AmountMode.card, const CalendarDate(2026, 10, 24));
      use(card);
      final BillStatus result = await status(card);
      expect(result.stamp, const BillStampWaiting(CalendarDate(2026, 10, 24)));
      expect(result.daysAway, -2);
    });

    test('once entered it is counted, not waiting', () async {
      final RecurringRule bill = waiting(AmountMode.varies, const CalendarDate(2026, 10, 24));
      use(bill);
      ledger.entries.add(postedFor(bill, const CalendarDate(2026, 10, 24)));
      expect((await status(bill)).stamp, const BillStampCounted(CalendarDate(2026, 10, 24)));
    });

    test('when the waiting bills can\'t be worked out, it shows as usual', () async {
      final RecurringRule bill = waiting(AmountMode.varies, WorkedExample.today);
      use(bill);
      recurring.failure = DatabaseFailure('locked');
      expect((await getStatus(bill).run()).isRight(), isTrue);
    });

    test('the waiting stamp compares by its date', () {
      expect(const BillStampWaiting(WorkedExample.today).props, <Object?>[WorkedExample.today]);
    });
  });
}

extension on Entry {
  Entry copyWithFor(int recurringId, CalendarDate on) => Entry(
        id: 100 + on.day,
        amount: amount,
        kind: kind,
        categoryId: categoryId,
        date: on,
        createdAt: createdAt,
        recurringId: recurringId,
      );
}
