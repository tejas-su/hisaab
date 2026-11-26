import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/amount_mode.dart';
import '../entities/entry_kind.dart';
import '../entities/occurrence.dart';
import '../entities/recurring_posting.dart';
import '../entities/recurring_rule.dart';
import '../entities/saving_totals.dart';
import '../due_amounts.dart';
import '../recurring_schedule.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import '../saving_caps.dart';
import '../set_aside.dart';

/// The recurring engine: posts every fixed rule's occurrences due up to today, catching up missed
/// ones (SPEC BR-9). Changing and card bills are never posted; they wait (D123).
///
/// Run at app start, on resume and when onboarding finishes. Idempotent: a repeat run or a crash
/// mid-run never double-posts, and a clock moved backwards posts nothing (E7–E9). A saving with a
/// target stops at it (BR-23).
final class PostDueRecurring implements UseCase<int, NoParams> {
  const PostDueRecurring({
    required this._recurring,
    required this._ledger,
    required this._clock,
  });

  final RecurringRepository _recurring;
  final LedgerRepository _ledger;
  final Clock _clock;

  /// Returns [Right] with the number of entries posted (0 when nothing was due), or [Left] with
  /// `DatabaseFailure` (from the rules or the saving totals), in which case nothing was posted.
  @override
  TaskEither<Failure, int> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return _recurring.activeRules().flatMap(
      (List<RecurringRule> rules) =>
          _ledger.savingTotals().flatMap((SavingTotals totals) {
            final RecurringPosting posting = _postingFor(rules, totals, today);
            // why: a saving past its target has no occurrences but its next_due still moves on (D213).
            return posting.nextDueByRuleId.isEmpty
                ? TaskEither<Failure, int>.right(0)
                : _recurring.post(posting);
          }),
    );
  }

  static RecurringPosting _postingFor(
    List<RecurringRule> rules,
    SavingTotals totals,
    CalendarDate today,
  ) {
    // why: a changing or card bill waits for the user to say how much; posting it would count
    // it twice (D123).
    final List<(RecurringRule, List<CalendarDate>)> due = rules
        .where((RecurringRule rule) => rule.amountMode == AmountMode.fixed)
        .map(
          (RecurringRule rule) => (
            rule,
            RecurringSchedule.datesFrom(
              rule.schedule,
              rule.nextDue,
              through: today,
            ),
          ),
        )
        .where(((RecurringRule, List<CalendarDate>) item) => item.$2.isNotEmpty)
        .toList();
    return RecurringPosting(
      occurrences: <Occurrence>[
        for (final (RecurringRule rule, List<CalendarDate> dates) in due)
          ..._occurrencesOf(rule, dates, totals),
      ],
      nextDueByRuleId: <int, CalendarDate>{
        for (final (RecurringRule rule, List<CalendarDate> dates) in due)
          rule.id: RecurringSchedule.next(rule.schedule, dates.last),
      },
    );
  }

  static List<Occurrence> _occurrencesOf(
    RecurringRule rule,
    List<CalendarDate> dates,
    SavingTotals totals,
  ) {
    if (rule.kind != EntryKind.saved || rule.target.isNone()) {
      return dates
          .map((CalendarDate date) => Occurrence(rule: rule, date: date))
          .toList();
    }
    final ({Money putIn, Money used}) saved =
        totals.bySaving[rule.id] ?? (putIn: Money.zero, used: Money.zero);
    return _upToTarget(rule, dates, SetAside.of(saved.putIn, saved.used));
  }

  // why: a user's own put-in is never capped (D33): only the engine's posting stops at the target.
  static List<Occurrence> _upToTarget(
    RecurringRule rule,
    List<CalendarDate> dates,
    Money setAside,
  ) =>
      SavingCaps.capped(
            rule,
            dates
                .map((CalendarDate date) => (date: date, amount: rule.amount))
                .toList(),
            setAside,
          )
          .map(
            (DatedAmount due) => Occurrence(
              rule: rule.copyWith(amount: due.amount),
              date: due.date,
            ),
          )
          .toList();
}
