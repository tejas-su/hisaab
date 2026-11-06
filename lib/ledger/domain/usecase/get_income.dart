import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../entities/entry_kind.dart';
import '../entities/income.dart';
import '../entities/recurring_rule.dart';
import '../recurring_schedule.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';

/// Loads the money coming in for Settings (SPEC FR-SE-1): the salary rule and its latest pay, or
/// for "It changes" what came in this month.
final class GetIncome implements UseCase<Income, NoParams> {
  const GetIncome({required this._recurring, required this._ledger, required this._clock});

  final RecurringRepository _recurring;
  final LedgerRepository _ledger;
  final Clock _clock;

  /// Returns [Right] with the [Income] (no rule for "It changes"), or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, Income> call(NoParams params) => _recurring.activeRules().flatMap(
    (List<RecurringRule> rules) =>
        Option<RecurringRule>.fromNullable(rules.where((RecurringRule rule) => rule.isIncomeSource).firstOrNull).match(
          () => _receivedThisMonth().map(
            (Money received) => Income(rule: const Option<RecurringRule>.none(), receivedThisMonth: received),
          ),
          (RecurringRule rule) => _latestPay(rule).map((Option<Entry> pay) => Income(rule: Option<RecurringRule>.of(rule), latestPay: pay)),
        ),
  );

  // why: the rule's last post is the occurrence before next_due, so one day's read finds it.
  TaskEither<Failure, Option<Entry>> _latestPay(RecurringRule rule) {
    final CalendarDate date = RecurringSchedule.previous(rule.schedule, rule.nextDue);
    return _ledger
        .entriesBetween(date, date)
        .map((List<Entry> entries) => Option<Entry>.fromNullable(entries.where((Entry e) => e.recurringId == rule.id).firstOrNull));
  }

  TaskEither<Failure, Money> _receivedThisMonth() {
    final CalendarDate today = _clock.today();
    return _ledger.entriesBetween(CalendarDate(today.year, today.month, 1), today).map(
          (List<Entry> entries) => entries
              .where((Entry e) => e.kind == EntryKind.got)
              .fold(Money.zero, (Money total, Entry e) => total + e.amount),
        );
  }
}
