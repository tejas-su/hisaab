import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/domain/waiting_bills.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));
const CalendarDate _today = CalendarDate(2026, 10, 26);
const CalendarDate _oct20 = CalendarDate(2026, 10, 20);

RecurringRule _bill({
  int id = 8,
  int day = 20,
  CalendarDate nextDue = _oct20,
  AmountMode mode = AmountMode.varies,
}) =>
    RecurringRule(
      id: id,
      label: 'Electricity',
      amount: Money.fromMajor(1200),
      kind: EntryKind.spent,
      categoryId: 5,
      schedule: Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, day)),
      nextDue: nextDue,
      amountMode: mode,
    );

Entry _entered(int ruleId, CalendarDate date) => Entry(
      id: 50,
      amount: Money.fromMajor(1460),
      kind: EntryKind.spent,
      categoryId: 5,
      date: date,
      createdAt: DateTime(2026, 10, 26, 9),
      recurringId: ruleId,
    );

List<Occurrence> _of(
  List<RecurringRule> rules, {
  List<Entry> entries = const <Entry>[],
  List<BillSkip> skips = const <BillSkip>[],
  CalendarDate today = _today,
  PayCycle cycle = _october,
}) =>
    WaitingBills.of(rules, entries: entries, skips: skips, today: today, cycle: cycle);

void main() {
  group('WaitingBills (D123)', () {
    test('a changing bill waits from its day', () {
      final RecurringRule bill = _bill();
      expect(_of(<RecurringRule>[bill]), <Occurrence>[Occurrence(rule: bill, date: _oct20)]);
    });

    test('a card bill waits too', () {
      final RecurringRule card = _bill(mode: AmountMode.card);
      expect(_of(<RecurringRule>[card]), <Occurrence>[Occurrence(rule: card, date: _oct20)]);
    });

    test('an entry on that date answers it', () {
      expect(_of(<RecurringRule>[_bill()], entries: <Entry>[_entered(8, _oct20)]), isEmpty);
    });

    test('another rule\'s entry on that date does not', () {
      expect(_of(<RecurringRule>[_bill()], entries: <Entry>[_entered(9, _oct20)]), hasLength(1));
    });

    test('a skip answers it', () {
      expect(_of(<RecurringRule>[_bill()], skips: const <BillSkip>[BillSkip(ruleId: 8, date: _oct20)]), isEmpty);
    });

    test('a fixed rule never waits', () {
      expect(_of(<RecurringRule>[_bill(mode: AmountMode.fixed)]), isEmpty);
    });

    test('a day after today does not wait yet', () {
      expect(_of(<RecurringRule>[_bill(day: 29, nextDue: const CalendarDate(2026, 10, 29))]), isEmpty);
    });

    test('last cycle\'s unanswered one drops out (E-c, E-g)', () {
      final RecurringRule bill = _bill(nextDue: const CalendarDate(2026, 7, 20));
      expect(_of(<RecurringRule>[bill]), <Occurrence>[Occurrence(rule: bill, date: _oct20)]);
    });

    test('nothing before next_due waits, so a bill added after its day waits next month (D33)', () {
      expect(_of(<RecurringRule>[_bill(nextDue: const CalendarDate(2026, 11, 20))]), isEmpty);
    });

    test('oldest first, then the rule saved first', () {
      final RecurringRule later = _bill(id: 9, day: 22, nextDue: const CalendarDate(2026, 10, 22));
      final RecurringRule second = _bill(id: 9);
      final RecurringRule first = _bill(id: 5);
      expect(
        _of(<RecurringRule>[later, second, first]).map((Occurrence o) => (o.rule.id, o.date)),
        <(int, CalendarDate)>[(5, _oct20), (9, _oct20), (9, const CalendarDate(2026, 10, 22))],
      );
    });

    test('a bill on the 31st waits on the 30th in a 30-day month (E-a)', () {
      final RecurringRule bill = RecurringRule(
        id: 8,
        label: 'Electricity',
        amount: Money.fromMajor(1200),
        kind: EntryKind.spent,
        categoryId: 5,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 31)),
        nextDue: const CalendarDate(2026, 10, 31),
        amountMode: AmountMode.varies,
      );
      expect(
        _of(
          <RecurringRule>[bill],
          today: const CalendarDate(2026, 11, 30),
          cycle: const PayCycle(start: CalendarDate(2026, 11, 4), end: CalendarDate(2026, 12, 3)),
        ),
        <Occurrence>[Occurrence(rule: bill, date: const CalendarDate(2026, 11, 30))],
      );
    });
  });
}
