import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/bill_reminders.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../bill_reminder_plan.dart';
import '../entities/cycle_summary.dart';
import '../entities/occurrence.dart';
import '../entities/recurring_rule.dart';
import '../repository/recurring_repository.dart';
import 'get_cycle_summary.dart';

/// Arms the due-day reminders of changing and card bills, or removes them all when the user
/// said no (spec §6, D126). Run on start, on resume and after every write; idempotent.
///
/// The param is whether the user wants reminders.
final class ArmBillReminders implements UseCase<Unit, bool> {
  const ArmBillReminders({required this._recurring, required this._summary, required this._reminders, required this._clock});

  final RecurringRepository _recurring;
  final GetCycleSummary _summary;
  final BillReminders _reminders;
  final Clock _clock;

  /// Returns [Right] with [unit] once the reminders are armed, or [Left] with `DatabaseFailure`
  /// when the bills can't be read, in which case nothing changes.
  @override
  TaskEither<Failure, Unit> call(bool params) {
    if (!params) {
      return _arm(const <Occurrence>[], const <RecurringRule>[]);
    }
    return _recurring.activeRules().flatMap((List<RecurringRule> rules) => _waiting().flatMap((List<Occurrence> waiting) => _arm(waiting, rules)));
  }

  // why: without the waiting bills a reminder shown today might be removed early, but the next
  // ones can still be armed, and Home's line still asks.
  TaskEither<Failure, List<Occurrence>> _waiting() => _summary(const NoParams())
      .map((CycleSummary summary) => summary.waitingBills)
      .orElse((Failure _) => TaskEither<Failure, List<Occurrence>>.right(const <Occurrence>[]));

  TaskEither<Failure, Unit> _arm(List<Occurrence> waiting, List<RecurringRule> rules) => TaskEither<Failure, Unit>(() async {
        await _reminders.arm(
          BillReminderPlan.upcoming(rules, waiting: waiting, now: _clock.now()),
          keep: BillReminderPlan.stillWaiting(waiting),
        );
        return Either<Failure, Unit>.right(unit);
      });
}
