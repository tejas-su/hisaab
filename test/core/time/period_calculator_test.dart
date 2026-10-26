import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:fpdart/fpdart.dart';
import 'package:expense_tracker/core/time/month_start.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PeriodCalculator calculator = PeriodCalculator();

  PayCycle cycle(CalendarDate today, PayRule rule, [MonthStart start = MonthStart.payday]) =>
      calculator.cycleFor(today: today, rule: rule, monthStart: start);

  group('PeriodCalculator.cycleFor — monthly on a day (SPEC BR-1)', () {
    test('worked example: payday 4th, today 26 Oct 2026', () {
      expect(
        cycle(const CalendarDate(2026, 10, 26), const MonthlyOnDay(4)),
        const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
      );
    });

    test('payday itself starts a new cycle', () {
      expect(
        cycle(const CalendarDate(2026, 11, 4), const MonthlyOnDay(4)).start,
        const CalendarDate(2026, 11, 4),
      );
    });

    test('the day before payday is the last day of the cycle', () {
      expect(
        cycle(const CalendarDate(2026, 11, 3), const MonthlyOnDay(4)),
        const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
      );
    });

    test('payday on the 31st clamps to 30 Sep, 31 Oct, 30 Nov', () {
      expect(
        cycle(const CalendarDate(2026, 10, 15), const MonthlyOnDay(31)),
        const PayCycle(start: CalendarDate(2026, 9, 30), end: CalendarDate(2026, 10, 30)),
      );
      expect(
        cycle(const CalendarDate(2026, 11, 15), const MonthlyOnDay(31)),
        const PayCycle(start: CalendarDate(2026, 10, 31), end: CalendarDate(2026, 11, 29)),
      );
    });

    test('E1: payday on the 31st in February 2027 and leap 2028', () {
      expect(cycle(const CalendarDate(2027, 3, 1), const MonthlyOnDay(31)).start, const CalendarDate(2027, 2, 28));
      expect(cycle(const CalendarDate(2028, 3, 1), const MonthlyOnDay(31)).start, const CalendarDate(2028, 2, 29));
      expect(cycle(const CalendarDate(2028, 3, 1), const MonthlyOnDay(31)).end, const CalendarDate(2028, 3, 30));
    });

    test('E3: a cycle crossing the year', () {
      expect(
        cycle(const CalendarDate(2027, 1, 10), const MonthlyOnDay(25)),
        const PayCycle(start: CalendarDate(2026, 12, 25), end: CalendarDate(2027, 1, 24)),
      );
    });

    test('payday on the 1st matches the calendar month', () {
      expect(
        cycle(const CalendarDate(2026, 2, 14), const MonthlyOnDay(1)),
        const PayCycle(start: CalendarDate(2026, 2, 1), end: CalendarDate(2026, 2, 28)),
      );
    });
  });

  group('PeriodCalculator.cycleFor — other rules', () {
    test('last day of the month', () {
      expect(
        cycle(const CalendarDate(2026, 10, 15), const LastDayOfMonth()),
        const PayCycle(start: CalendarDate(2026, 9, 30), end: CalendarDate(2026, 10, 30)),
      );
      expect(cycle(const CalendarDate(2026, 10, 31), const LastDayOfMonth()).start, const CalendarDate(2026, 10, 31));
    });

    test('weekly on a weekday spans seven days', () {
      expect(
        cycle(const CalendarDate(2026, 10, 28), const WeeklyOn(DateTime.monday)),
        const PayCycle(start: CalendarDate(2026, 10, 26), end: CalendarDate(2026, 11, 1)),
      );
      expect(
        cycle(const CalendarDate(2026, 10, 26), const WeeklyOn(DateTime.monday)).start,
        const CalendarDate(2026, 10, 26),
      );
    });

    test('irregular income uses the calendar month', () {
      expect(
        cycle(const CalendarDate(2026, 10, 26), const IrregularIncome()),
        const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)),
      );
    });

    test('month start "1st of month" overrides any pay rule', () {
      expect(
        cycle(const CalendarDate(2026, 10, 26), const MonthlyOnDay(4), MonthStart.firstOfMonth),
        const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)),
      );
    });
  });

  group('PayCycle', () {
    const PayCycle october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

    test('BR-2: days left counts today', () {
      expect(october.daysLeftFrom(const CalendarDate(2026, 10, 26)), 9);
    });

    test('E2: on the last day exactly one day is left', () {
      expect(october.daysLeftFrom(const CalendarDate(2026, 11, 3)), 1);
    });

    test('length and elapsed days', () {
      expect(october.lengthInDays, 31);
      expect(october.daysElapsedBefore(const CalendarDate(2026, 10, 26)), 22);
    });

    test('contains its own boundaries only', () {
      expect(october.contains(const CalendarDate(2026, 10, 4)), isTrue);
      expect(october.contains(const CalendarDate(2026, 11, 3)), isTrue);
      expect(october.contains(const CalendarDate(2026, 11, 4)), isFalse);
      expect(october.contains(const CalendarDate(2026, 10, 3)), isFalse);
    });

    test('E15: no monthly or weekly cycle exceeds 31 days', () {
      const List<PayRule> rules = <PayRule>[
        MonthlyOnDay(1),
        MonthlyOnDay(15),
        MonthlyOnDay(29),
        MonthlyOnDay(30),
        MonthlyOnDay(31),
        LastDayOfMonth(),
        WeeklyOn(DateTime.friday),
        IrregularIncome(),
      ];
      final Iterable<int> lengths = rules.expand(
        (PayRule rule) => List<int>.generate(800, (int i) => i).map(
          (int offset) => cycle(const CalendarDate(2026, 1, 1).addDays(offset), rule).lengthInDays,
        ),
      );
      expect(lengths.every((int length) => length >= 7 && length <= 31), isTrue);
    });
  });

  group('PayRule validation', () {
    test('rejects impossible days and weekdays with InvalidDataFailure', () {
      expect(MonthlyOnDay.validate(0).getLeft().toNullable(), isA<InvalidDataFailure>());
      expect(MonthlyOnDay.validate(32).isLeft(), isTrue);
      expect(WeeklyOn.validate(0).isLeft(), isTrue);
      expect(WeeklyOn.validate(8).isLeft(), isTrue);
    });

    test('rules compare by value', () {
      expect(const LastDayOfMonth().props, isEmpty);
      expect(const IrregularIncome().props, isEmpty);
      expect(const LastDayOfMonth().hashCode, const LastDayOfMonth().hashCode);
      expect(const LastDayOfMonth() == const IrregularIncome(), isFalse);
    });

    test('accepts the boundary values', () {
      expect(MonthlyOnDay.validate(1), Either<Failure, PayRule>.right(const MonthlyOnDay(1)));
      expect(MonthlyOnDay.validate(31), Either<Failure, PayRule>.right(const MonthlyOnDay(31)));
      expect(WeeklyOn.validate(DateTime.sunday), Either<Failure, PayRule>.right(const WeeklyOn(DateTime.sunday)));
    });
  });
}
