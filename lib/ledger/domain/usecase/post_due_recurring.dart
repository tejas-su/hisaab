import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/occurrence.dart';
import '../entities/recurring_posting.dart';
import '../entities/recurring_rule.dart';
import '../recurring_schedule.dart';
import '../repository/recurring_repository.dart';

/// The recurring engine: posts every occurrence due up to today, catching up missed ones (SPEC BR-9).
///
/// Run at app start, on resume and when onboarding finishes. Idempotent: a repeat run or a crash
/// mid-run never double-posts, and a clock moved backwards posts nothing (E7–E9).
final class PostDueRecurring implements UseCase<int, NoParams> {
  const PostDueRecurring({required this._recurring, required this._clock});

  final RecurringRepository _recurring;
  final Clock _clock;

  /// Returns [Right] with the number of entries posted (0 when nothing was due), or [Left] with
  /// `DatabaseFailure`, in which case nothing was posted.
  @override
  TaskEither<Failure, int> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return _recurring.activeRules().flatMap((List<RecurringRule> rules) {
      final RecurringPosting posting = _postingFor(rules, today);
      return posting.isEmpty ? TaskEither<Failure, int>.right(0) : _recurring.post(posting);
    });
  }

  static RecurringPosting _postingFor(List<RecurringRule> rules, CalendarDate today) {
    final List<(RecurringRule, List<CalendarDate>)> due = rules
        .map((RecurringRule rule) => (rule, RecurringSchedule.datesFrom(rule.schedule, rule.nextDue, through: today)))
        .where(((RecurringRule, List<CalendarDate>) item) => item.$2.isNotEmpty)
        .toList();
    return RecurringPosting(
      occurrences: <Occurrence>[
        for (final (RecurringRule rule, List<CalendarDate> dates) in due)
          for (final CalendarDate date in dates) Occurrence(rule: rule, date: date),
      ],
      nextDueByRuleId: <int, CalendarDate>{
        for (final (RecurringRule rule, List<CalendarDate> dates) in due)
          rule.id: RecurringSchedule.next(rule.schedule, dates.last),
      },
    );
  }
}
