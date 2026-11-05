import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import 'entities/amount_mode.dart';
import 'entities/bill_skip.dart';
import 'entities/entry.dart';
import 'entities/occurrence.dart';
import 'entities/recurring_rule.dart';
import 'recurring_schedule.dart';

/// Finds the changing and card bills waiting for the user to say how much (D123).
///
/// An occurrence waits when it falls in this cycle on or before today, not before the rule's
/// `next_due` (D33), and has neither an entry nor a skip. Nothing is stored, so deleting an
/// entered bill makes it wait again, and last cycle's unanswered bill drops out (E-c, E-g).
abstract final class WaitingBills {
  /// The waiting occurrences of [rules], oldest first, then by the rule saved first.
  static List<Occurrence> of(
    Iterable<RecurringRule> rules, {
    required List<Entry> entries,
    required List<BillSkip> skips,
    required CalendarDate today,
    required PayCycle cycle,
  }) {
    final Set<(int, CalendarDate)> answered = <(int, CalendarDate)>{
      for (final Entry entry in entries)
        if (entry.recurringId case final int ruleId) (ruleId, entry.date),
      for (final BillSkip skip in skips) (skip.ruleId, skip.date),
    };
    final List<Occurrence> waiting = rules
        .where((RecurringRule rule) => rule.amountMode != AmountMode.fixed)
        .expand((RecurringRule rule) => _datesUpTo(rule, today, cycle).map((CalendarDate date) => Occurrence(rule: rule, date: date)))
        .where((Occurrence occurrence) => !answered.contains((occurrence.rule.id, occurrence.date)))
        .toList();
    return waiting..sort(_oldestFirst);
  }

  static Iterable<CalendarDate> _datesUpTo(RecurringRule rule, CalendarDate today, PayCycle cycle) {
    final CalendarDate from = rule.nextDue.isAfter(cycle.start) ? rule.nextDue : cycle.start;
    return RecurringSchedule.datesFrom(rule.schedule, RecurringSchedule.firstOnOrAfter(rule.schedule, from), through: today);
  }

  static int _oldestFirst(Occurrence a, Occurrence b) =>
      a.date == b.date ? a.rule.id.compareTo(b.rule.id) : a.date.compareTo(b.date);
}
