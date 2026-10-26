import 'package:fpdart/fpdart.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/pay_rule.dart';
import 'entities/frequency.dart';
import 'entities/recurring_rule.dart';
import 'entities/schedule.dart';
import 'recurring_schedule.dart';

/// Converts between the onboarding [PayRule] and the salary rule's [Schedule] (DECISIONS D20:
/// the pay rule lives on the income recurring row).
abstract final class PayRuleSchedule {
  /// The salary schedule for [rule], anchored near [today].
  ///
  /// Returns [None] for [IrregularIncome], which has no salary rule.
  static Option<Schedule> scheduleFor(PayRule rule, {required CalendarDate today}) => switch (rule) {
        MonthlyOnDay(:final int day) => Option<Schedule>.of(
            Schedule(frequency: Frequency.monthly, anchor: RecurringSchedule.monthlyAnchor(day, near: today)),
          ),
        LastDayOfMonth() => Option<Schedule>.of(
            Schedule(
              frequency: Frequency.monthly,
              anchor: CalendarDate(today.year, today.month, CalendarDate.daysInMonth(today.year, today.month)),
              lastDayOfMonth: true,
            ),
          ),
        WeeklyOn(:final int weekday) => Option<Schedule>.of(
            Schedule(frequency: Frequency.weekly, anchor: today.addDays(-((today.weekday - weekday) % 7))),
          ),
        IrregularIncome() => const Option<Schedule>.none(),
      };

  /// The pay rule implied by the salary rule [income]; without one, cycles follow the calendar month.
  static PayRule payRuleOf(Option<RecurringRule> income) => income.match(
        () => const IrregularIncome(),
        (RecurringRule rule) => _payRuleOfSchedule(rule.schedule),
      );

  // why: SPEC BR-1 defines no 14-day or yearly cycles, so those salaries use calendar months.
  static PayRule _payRuleOfSchedule(Schedule schedule) => switch (schedule.frequency) {
        Frequency.monthly when schedule.lastDayOfMonth => const LastDayOfMonth(),
        Frequency.monthly => MonthlyOnDay(schedule.anchor.day),
        Frequency.weekly => WeeklyOn(schedule.anchor.weekday),
        Frequency.biweekly || Frequency.yearly => const IrregularIncome(),
      };
}
