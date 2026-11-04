import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/due_soon_bill.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../recurring_schedule.dart';
import '../repository/recurring_repository.dart';

/// Finds the soonest unposted bill or saving occurrence within the next [window] days (SPEC BR-9, D120).
final class GetDueSoonBill implements UseCase<Option<DueSoonBill>, NoParams> {
  const GetDueSoonBill({required this._recurring, required this._clock});

  /// How many days ahead a bill counts as "due soon".
  static const int window = 5;

  final RecurringRepository _recurring;
  final Clock _clock;

  /// Returns [Right] with the soonest bill (the first rule on a tie), [None] when nothing is due
  /// within [window] days, or [Left] with `DatabaseFailure` when the rules can't be read.
  @override
  TaskEither<Failure, Option<DueSoonBill>> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return _recurring.activeRules().map((List<RecurringRule> rules) => _soonest(rules, today));
  }

  static Option<DueSoonBill> _soonest(List<RecurringRule> rules, CalendarDate today) {
    final Iterable<DueSoonBill> soon = rules
        .where((RecurringRule rule) => rule.kind == EntryKind.spent || rule.kind == EntryKind.saved)
        .map((RecurringRule rule) => _nextOf(rule, today))
        .where((DueSoonBill bill) => bill.daysAway <= window);
    return Option<DueSoonBill>.fromNullable(
      soon.fold<DueSoonBill?>(null, (DueSoonBill? best, DueSoonBill bill) => best == null || bill.daysAway < best.daysAway ? bill : best),
    );
  }

  static DueSoonBill _nextOf(RecurringRule rule, CalendarDate today) {
    final CalendarDate due = RecurringSchedule.firstUnpostedAfter(rule.schedule, rule.nextDue, today: today);
    return DueSoonBill(rule: rule, dueDate: due, daysAway: today.daysUntil(due));
  }
}
