import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';
import 'package:expense_tracker/ledger/domain/pay_rule_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);

RecurringRule _salary(Schedule schedule) => RecurringRule(
      id: 1,
      label: 'Salary',
      amount: Money.fromMajor(45000),
      kind: EntryKind.got,
      categoryId: 9,
      schedule: schedule,
      nextDue: _today,
      isIncomeSource: true,
    );

void main() {
  group('PayRuleSchedule.scheduleFor', () {
    test('monthly on a day anchors on that day', () {
      expect(
        PayRuleSchedule.scheduleFor(const MonthlyOnDay(4), today: _today),
        const Option<Schedule>.of(Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 4))),
      );
    });

    test('monthly on the 31st anchors in a 31-day month', () {
      expect(
        PayRuleSchedule.scheduleFor(const MonthlyOnDay(31), today: const CalendarDate(2026, 11, 2)),
        const Option<Schedule>.of(Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 31))),
      );
    });

    test('last day of month sets the flag', () {
      expect(
        PayRuleSchedule.scheduleFor(const LastDayOfMonth(), today: _today),
        const Option<Schedule>.of(
          Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 31), lastDayOfMonth: true),
        ),
      );
    });

    test('weekly anchors on the latest such weekday', () {
      expect(
        PayRuleSchedule.scheduleFor(const WeeklyOn(DateTime.friday), today: _today),
        const Option<Schedule>.of(Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23))),
      );
    });

    test('irregular income has no schedule', () {
      expect(PayRuleSchedule.scheduleFor(const IrregularIncome(), today: _today), const Option<Schedule>.none());
    });
  });

  group('PayRuleSchedule.payRuleOf', () {
    final List<PayRule> roundTrips = <PayRule>[
      const MonthlyOnDay(1),
      const MonthlyOnDay(4),
      const MonthlyOnDay(31),
      const LastDayOfMonth(),
      const WeeklyOn(DateTime.monday),
      const WeeklyOn(DateTime.sunday),
    ];
    for (final PayRule rule in roundTrips) {
      test('round-trips $rule through the salary rule', () {
        final Schedule schedule = PayRuleSchedule.scheduleFor(rule, today: _today).getOrElse(() => fail('no schedule'));
        expect(PayRuleSchedule.payRuleOf(Option<RecurringRule>.of(_salary(schedule))), rule);
      });
    }

    test('no salary rule means irregular income (calendar months)', () {
      expect(PayRuleSchedule.payRuleOf(const Option<RecurringRule>.none()), const IrregularIncome());
    });

    for (final Frequency frequency in <Frequency>[Frequency.biweekly, Frequency.yearly]) {
      test('a ${frequency.name} salary falls back to calendar months', () {
        final Schedule schedule = Schedule(frequency: frequency, anchor: _today);
        expect(PayRuleSchedule.payRuleOf(Option<RecurringRule>.of(_salary(schedule))), const IrregularIncome());
      });
    }
  });
}
