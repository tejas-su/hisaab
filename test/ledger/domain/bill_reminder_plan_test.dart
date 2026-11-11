import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  RecurringRule bill(AmountMode mode, int day, {CalendarDate? nextDue}) => WorkedExample.electricity.copyWith(
        label: mode == AmountMode.card ? 'Credit card' : 'Electricity',
        amountMode: mode,
        schedule: Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, day)),
        nextDue: nextDue ?? CalendarDate(2026, 10, day),
      );
  // Mon 26 Oct 2026.
  final DateTime early = DateTime(2026, 10, 26, 7, 30);
  final DateTime late = DateTime(2026, 10, 26, 9);

  List<BillReminder> upcoming(List<RecurringRule> rules, {List<Occurrence> waiting = const <Occurrence>[], DateTime? now}) =>
      BillReminderPlan.upcoming(rules, waiting: waiting, now: now ?? early);

  group('BillReminderPlan.upcoming (spec §6)', () {
    test('a changing bill later this month is reminded at 9 on its day', () {
      expect(upcoming(<RecurringRule>[bill(AmountMode.varies, 29)]), <BillReminder>[
        BillReminder(ruleId: 3, date: const CalendarDate(2026, 10, 29), billName: 'Electricity', isCard: false, at: DateTime(2026, 10, 29, 9)),
      ]);
    });

    test('a card bill says it is a card bill', () {
      expect(upcoming(<RecurringRule>[bill(AmountMode.card, 29)]).single.isCard, isTrue);
    });

    test('fixed bills, income and savings get none', () {
      expect(upcoming(<RecurringRule>[WorkedExample.salary, WorkedExample.rent, WorkedExample.rd]), isEmpty);
    });

    test('one due today and still waiting before 9 is reminded today', () {
      final RecurringRule today = bill(AmountMode.varies, 26);
      expect(
        upcoming(<RecurringRule>[today], waiting: <Occurrence>[Occurrence(rule: today, date: WorkedExample.today)]).single.date,
        WorkedExample.today,
      );
    });

    test('one due today but 9 has passed moves to next month: no reminder after the fact', () {
      final RecurringRule today = bill(AmountMode.varies, 26);
      expect(
        upcoming(<RecurringRule>[today], waiting: <Occurrence>[Occurrence(rule: today, date: WorkedExample.today)], now: late).single.date,
        const CalendarDate(2026, 11, 26),
      );
    });

    test('one due today and already answered moves to next month', () {
      expect(upcoming(<RecurringRule>[bill(AmountMode.varies, 26)]).single.date, const CalendarDate(2026, 11, 26));
    });

    test('one whose day has passed this month is reminded next month', () {
      expect(upcoming(<RecurringRule>[bill(AmountMode.card, 20)]).single.date, const CalendarDate(2026, 11, 20));
    });

    test('a bill added after its day starts from its next_due (D33)', () {
      expect(
        upcoming(<RecurringRule>[bill(AmountMode.varies, 20, nextDue: const CalendarDate(2026, 12, 20))]).single.date,
        const CalendarDate(2026, 12, 20),
      );
    });

    test('day 31 is clamped as BR-1 does: 30 Nov', () {
      expect(upcoming(<RecurringRule>[bill(AmountMode.varies, 31, nextDue: const CalendarDate(2026, 10, 31))], now: DateTime(2026, 11, 1, 8)).single.date,
          const CalendarDate(2026, 11, 30));
    });
  });

  group('BillReminderPlan.stillWaiting', () {
    test('keeps the reminder of every bill still waiting, so a shown one stays', () {
      final RecurringRule card = bill(AmountMode.card, 24);
      expect(
        BillReminderPlan.stillWaiting(<Occurrence>[Occurrence(rule: card, date: const CalendarDate(2026, 10, 24))]),
        <int>{BillReminder.idFor(3, const CalendarDate(2026, 10, 24))},
      );
    });
  });
}
