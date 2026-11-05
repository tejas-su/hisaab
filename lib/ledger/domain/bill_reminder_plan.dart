import '../../core/notifications/bill_reminder.dart';
import '../../core/time/calendar_date.dart';
import 'entities/amount_mode.dart';
import 'entities/entry_kind.dart';
import 'entities/occurrence.dart';
import 'entities/recurring_rule.dart';
import 'recurring_schedule.dart';

/// Works out which due-day reminders should be armed (spec §6, D126).
abstract final class BillReminderPlan {
  /// The reminders show at about this hour on the due day.
  static const int hour = 9;

  /// The next reminder of each changing or card bill in [rules]: its next due day, at [hour].
  ///
  /// Today's occurrence counts only while it is still in [waiting] and [now] is before [hour];
  /// otherwise the reminder moves to the next month, so none is ever shown after the fact.
  static List<BillReminder> upcoming(Iterable<RecurringRule> rules, {required List<Occurrence> waiting, required DateTime now}) {
    final CalendarDate today = CalendarDate.fromDateTime(now);
    return rules
        .where((RecurringRule rule) => rule.kind == EntryKind.spent && rule.amountMode != AmountMode.fixed)
        .map((RecurringRule rule) => _reminder(rule, _nextDate(rule, today, remindToday: now.hour < hour && _waitsOn(waiting, rule, today))))
        .toList();
  }

  /// The ids of the reminders of [waiting] bills, so one already shown stays until it is answered.
  static Set<int> stillWaiting(List<Occurrence> waiting) =>
      waiting.map((Occurrence o) => BillReminder.idFor(o.rule.id, o.date)).toSet();

  static CalendarDate _nextDate(RecurringRule rule, CalendarDate today, {required bool remindToday}) {
    final CalendarDate first = RecurringSchedule.firstOnOrAfter(rule.schedule, rule.nextDue.isAfter(today) ? rule.nextDue : today);
    return first == today && !remindToday ? RecurringSchedule.next(rule.schedule, first) : first;
  }

  static bool _waitsOn(List<Occurrence> waiting, RecurringRule rule, CalendarDate date) =>
      waiting.any((Occurrence o) => o.rule.id == rule.id && o.date == date);

  static BillReminder _reminder(RecurringRule rule, CalendarDate date) => BillReminder(
        ruleId: rule.id,
        date: date,
        billName: rule.label,
        isCard: rule.amountMode == AmountMode.card,
        at: DateTime(date.year, date.month, date.day, hour),
      );
}
