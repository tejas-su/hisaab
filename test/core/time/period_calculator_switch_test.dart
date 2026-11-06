import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/month_start.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/core/time/pay_switch.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PeriodCalculator calculator = PeriodCalculator();
  const CalendarDate oct26 = CalendarDate(2026, 10, 26);

  PayCycle cycle(CalendarDate today, PayRule rule, List<PaySwitch> switches, [MonthStart start = MonthStart.payday]) =>
      calculator.cycleFor(today: today, rule: rule, monthStart: start, switches: switches);

  PayCycle span(CalendarDate start, CalendarDate end) => PayCycle(start: start, end: end);

  group('PeriodCalculator.cycleFor — a changed payday bridges the cycle it falls in (BR-1a, D140)', () {
    const List<PaySwitch> to25 = <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(4))];

    test('worked example: payday 4th moved to the 25th on 26 Oct runs 4 Oct to 24 Nov', () {
      expect(cycle(oct26, const MonthlyOnDay(25), to25), span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 24)));
    });

    test('every day of the bridge is in it, and the next cycle follows the new payday', () {
      expect(cycle(const CalendarDate(2026, 10, 4), const MonthlyOnDay(25), to25).end, const CalendarDate(2026, 11, 24));
      expect(cycle(const CalendarDate(2026, 11, 24), const MonthlyOnDay(25), to25).start, const CalendarDate(2026, 10, 4));
      expect(cycle(const CalendarDate(2026, 11, 25), const MonthlyOnDay(25), to25),
          span(const CalendarDate(2026, 11, 25), const CalendarDate(2026, 12, 24)));
    });

    test('cycles before the change keep the old payday', () {
      expect(cycle(const CalendarDate(2026, 10, 3), const MonthlyOnDay(25), to25),
          span(const CalendarDate(2026, 9, 4), const CalendarDate(2026, 10, 3)));
    });

    test('moving payday earlier ends this cycle the day before it', () {
      expect(cycle(oct26, const MonthlyOnDay(1), const <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(4))]),
          span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 10, 31)));
    });

    test('a new payday of today starts next month, never today', () {
      expect(cycle(oct26, const MonthlyOnDay(26), const <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(4))]),
          span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 25)));
    });

    test('changing back the same day restores the old cycle exactly', () {
      const List<PaySwitch> there = <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(4)), PaySwitch(on: oct26, from: MonthlyOnDay(25))];
      expect(cycle(oct26, const MonthlyOnDay(4), there), span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 3)));
    });

    test('a second change inside the bridge keeps the bridge\'s start', () {
      const List<PaySwitch> twice = <PaySwitch>[
        PaySwitch(on: oct26, from: MonthlyOnDay(4)),
        PaySwitch(on: CalendarDate(2026, 11, 10), from: MonthlyOnDay(25)),
      ];
      expect(cycle(const CalendarDate(2026, 11, 10), const MonthlyOnDay(15), twice),
          span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 14)));
      expect(cycle(oct26, const MonthlyOnDay(15), twice), span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 14)));
    });

    test('a payday on the 31st clamps in the bridge\'s end', () {
      const CalendarDate feb10 = CalendarDate(2027, 2, 10);
      expect(cycle(feb10, const MonthlyOnDay(31), const <PaySwitch>[PaySwitch(on: feb10, from: MonthlyOnDay(4))]),
          span(const CalendarDate(2027, 2, 4), const CalendarDate(2027, 2, 27)));
    });

    test('a bridge can cross the year', () {
      const CalendarDate dec26 = CalendarDate(2026, 12, 26);
      expect(cycle(dec26, const MonthlyOnDay(25), const <PaySwitch>[PaySwitch(on: dec26, from: MonthlyOnDay(4))]),
          span(const CalendarDate(2026, 12, 4), const CalendarDate(2027, 1, 24)));
    });

    test('monthly to weekly ends the bridge with the new week', () {
      expect(cycle(oct26, const WeeklyOn(DateTime.friday), const <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(4))]),
          span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 10, 29)));
    });

    test('weekly to monthly starts the bridge on the last payday', () {
      expect(cycle(oct26, const MonthlyOnDay(1), const <PaySwitch>[PaySwitch(on: oct26, from: WeeklyOn(DateTime.friday))]),
          span(const CalendarDate(2026, 10, 23), const CalendarDate(2026, 10, 31)));
    });

    test('to "It changes" ends the bridge at month end', () {
      expect(cycle(oct26, const IrregularIncome(), const <PaySwitch>[PaySwitch(on: oct26, from: MonthlyOnDay(25))]),
          span(const CalendarDate(2026, 10, 25), const CalendarDate(2026, 10, 31)));
    });

    test('from "It changes" starts the bridge on the 1st', () {
      expect(cycle(oct26, const LastDayOfMonth(), const <PaySwitch>[PaySwitch(on: oct26, from: IrregularIncome())]),
          span(const CalendarDate(2026, 10, 1), const CalendarDate(2026, 10, 30)));
    });

    test('month start on the 1st ignores the change', () {
      expect(cycle(oct26, const MonthlyOnDay(25), to25, MonthStart.firstOfMonth),
          span(const CalendarDate(2026, 10, 1), const CalendarDate(2026, 10, 31)));
    });

    test('no switches is the plain rule', () {
      expect(cycle(oct26, const MonthlyOnDay(4), const <PaySwitch>[]), span(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 11, 3)));
    });
  });

  test('PaySwitch compares by its fields', () {
    expect(const PaySwitch(on: oct26, from: MonthlyOnDay(4)), const PaySwitch(on: oct26, from: MonthlyOnDay(4)));
    expect(const PaySwitch(on: oct26, from: MonthlyOnDay(4)), isNot(const PaySwitch(on: oct26, from: MonthlyOnDay(5))));
  });
}
