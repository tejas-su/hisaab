import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import 'entities/amount_mode.dart';
import 'entities/bill_skip.dart';
import 'entities/entry.dart';
import 'entities/frequency.dart';
import 'entities/occurrence.dart';
import 'entities/recurring_rule.dart';
import 'recurring_schedule.dart';

/// Finds the changing and card bills waiting for the user to say how much (D123).
///
/// An occurrence waits when it falls in this cycle on or before today, not before the rule's
/// `next_due` (D33), and its month has neither an entry nor a skip of that rule. Nothing is
/// stored, so deleting an entered bill makes it wait again, and last cycle's unanswered bill drops
/// out (E-c, E-g).
abstract final class WaitingBills {
  /// The waiting occurrences of [rules], oldest first, then by the rule saved first.
  static List<Occurrence> of(
    Iterable<RecurringRule> rules, {
    required List<Entry> entries,
    required List<BillSkip> skips,
    required CalendarDate today,
    required PayCycle cycle,
  }) =>
      unanswered(rules, entries: entries, skips: skips, through: today, cycle: cycle);

  /// The occurrences of [rules] in [cycle] up to [through] that are still unanswered: the waiting
  /// ones, and, through the cycle's end, the ones still to come that `B` reserves at the estimate.
  ///
  /// [entries] and [skips] must reach back to the first day of the month [cycle] starts in, so an
  /// answer given earlier that month is seen.
  static List<Occurrence> unanswered(
    Iterable<RecurringRule> rules, {
    required List<Entry> entries,
    required List<BillSkip> skips,
    required CalendarDate through,
    required PayCycle cycle,
  }) {
    final Set<(int, CalendarDate)> answered = <(int, CalendarDate)>{
      for (final Entry entry in entries)
        if (entry.recurringId case final int ruleId) (ruleId, entry.date),
      for (final BillSkip skip in skips) (skip.ruleId, skip.date),
    };
    final List<Occurrence> waiting = rules
        .where((RecurringRule rule) => rule.amountMode != AmountMode.fixed)
        .expand((RecurringRule rule) => _datesUpTo(rule, through, cycle).map((CalendarDate date) => Occurrence(rule: rule, date: date)))
        .where((Occurrence occurrence) => !answered.any(((int, CalendarDate) answer) => _answers(answer, occurrence)))
        .toList();
    return waiting..sort(_oldestFirst);
  }

  /// The first day the answers for [cycle] must be read from (see [unanswered]).
  static CalendarDate answersFrom(PayCycle cycle) => CalendarDate(cycle.start.year, cycle.start.month, 1);

  // why: a monthly bill is answered once a month. An entry whose date was edited, or a bill whose
  // day was moved after it was entered, must not ask (and reserve) the same month twice.
  static bool _answers((int, CalendarDate) answer, Occurrence occurrence) {
    final (int ruleId, CalendarDate date) = answer;
    if (ruleId != occurrence.rule.id) {
      return false;
    }
    if (occurrence.rule.schedule.frequency != Frequency.monthly) {
      return date == occurrence.date;
    }
    return date.year == occurrence.date.year && date.month == occurrence.date.month;
  }

  static Iterable<CalendarDate> _datesUpTo(RecurringRule rule, CalendarDate through, PayCycle cycle) {
    final CalendarDate from = rule.nextDue.isAfter(cycle.start) ? rule.nextDue : cycle.start;
    return RecurringSchedule.datesFrom(rule.schedule, RecurringSchedule.firstOnOrAfter(rule.schedule, from), through: through);
  }

  static int _oldestFirst(Occurrence a, Occurrence b) =>
      a.date == b.date ? a.rule.id.compareTo(b.rule.id) : a.date.compareTo(b.date);
}
