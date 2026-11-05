import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/amount_mode.dart';
import '../entities/bill_status.dart';
import '../entities/cycle_summary.dart';
import '../entities/entry.dart';
import '../entities/occurrence.dart';
import '../entities/recurring_rule.dart';
import '../recurring_schedule.dart';
import '../repository/ledger_repository.dart';
import 'get_cycle_summary.dart';
import 'get_due_soon_bill.dart';

/// Works out a bill's next date and the stamp the bill sheet shows (SPEC BR-9, D118).
///
/// "Due" wins inside the due-soon window. Otherwise the bill is "Counted" only when an entry
/// this rule posted is dated on or after the occurrence before `next_due`, so a bill added
/// after its day this month (D33) never claims to be counted. A changing or card bill still
/// waiting for its amount (D123) is "Waiting" first, dated the day it went out, as Home asks.
final class GetBillStatus implements UseCase<BillStatus, RecurringRule> {
  const GetBillStatus({required this._ledger, required this._clock, required this._summary});

  final LedgerRepository _ledger;
  final Clock _clock;
  final GetCycleSummary _summary;

  /// Returns [Right] with the status, or [Left] with `DatabaseFailure` when entries can't be read.
  @override
  TaskEither<Failure, BillStatus> call(RecurringRule rule) {
    if (rule.amountMode == AmountMode.fixed) {
      return _scheduled(rule);
    }
    // why: the waiting bills only add a stamp, so if they can't be worked out the bill shows as usual.
    return _summary(const NoParams())
        .map((CycleSummary summary) => summary.waitingBills.where((Occurrence o) => o.rule.id == rule.id).firstOrNull)
        .orElse((Failure _) => TaskEither<Failure, Occurrence?>.right(null))
        .flatMap((Occurrence? waiting) => waiting == null ? _scheduled(rule) : TaskEither<Failure, BillStatus>.right(_waiting(waiting)));
  }

  BillStatus _waiting(Occurrence occurrence) => BillStatus(
        nextDate: occurrence.date,
        daysAway: _clock.today().daysUntil(occurrence.date),
        stamp: BillStampWaiting(occurrence.date),
      );

  TaskEither<Failure, BillStatus> _scheduled(RecurringRule rule) {
    final CalendarDate today = _clock.today();
    final CalendarDate nextDate = RecurringSchedule.firstUnpostedAfter(rule.schedule, rule.nextDue, today: today);
    final int daysAway = today.daysUntil(nextDate);
    if (daysAway <= GetDueSoonBill.window) {
      return TaskEither<Failure, BillStatus>.right(BillStatus(nextDate: nextDate, daysAway: daysAway, stamp: BillStampDue(daysAway)));
    }
    return _ledger
        .entriesBetween(RecurringSchedule.previous(rule.schedule, rule.nextDue), today)
        .map((List<Entry> entries) => BillStatus(nextDate: nextDate, daysAway: daysAway, stamp: _countedStamp(entries, rule.id)));
  }

  static BillStamp _countedStamp(List<Entry> entries, int ruleId) {
    final Iterable<CalendarDate> dates = entries.where((Entry e) => e.recurringId == ruleId).map((Entry e) => e.date);
    return dates.isEmpty
        ? const BillStampNone()
        : BillStampCounted(dates.reduce((CalendarDate a, CalendarDate b) => a.isAfter(b) ? a : b));
  }
}
