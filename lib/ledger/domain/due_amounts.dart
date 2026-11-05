import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import 'entities/recurring_rule.dart';
import 'recurring_schedule.dart';

/// An amount due on a day.
typedef DatedAmount = ({CalendarDate date, Money amount});

/// Sums what recurring rules still have to post in a cycle (SPEC BR-3 `B`, and `R` for savings).
abstract final class DueAmounts {
  /// The occurrences of [rules] due after [today] up to the end of [cycle] and not yet posted.
  static Money after(Iterable<RecurringRule> rules, {required CalendarDate today, required PayCycle cycle}) =>
      datedAfter(rules, today: today, cycle: cycle).fold(Money.zero, (Money total, DatedAmount due) => total + due.amount);

  /// The same occurrences as [after], each on its own date (the pace chart's bill steps, D129).
  static List<DatedAmount> datedAfter(Iterable<RecurringRule> rules, {required CalendarDate today, required PayCycle cycle}) => rules
      .expand(
        (RecurringRule rule) => _datesAfter(rule, today, cycle).map((CalendarDate date) => (date: date, amount: rule.amount)),
      )
      .toList();

  static Iterable<CalendarDate> _datesAfter(RecurringRule rule, CalendarDate today, PayCycle cycle) {
    final CalendarDate first = RecurringSchedule.firstUnpostedAfter(rule.schedule, rule.nextDue, today: today);
    return RecurringSchedule.datesFrom(rule.schedule, first, through: cycle.end);
  }
}
