import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../bill_validator.dart';
import '../entities/bill_input.dart';
import '../entities/frequency.dart';
import '../entities/recurring_rule.dart';
import '../entities/schedule.dart';
import '../recurring_schedule.dart';
import '../repository/recurring_repository.dart';

/// A change to an existing bill [rule]: its new name, amount, due day and icon.
final class EditBillParams extends Equatable {
  const EditBillParams({required this.rule, required this.input});

  final RecurringRule rule;
  final BillInput input;

  @override
  List<Object?> get props => <Object?>[rule, input];
}

/// Changes a fixed bill from Settings; only future occurrences change (SPEC BR-9, FR-SE-1).
///
/// The schedule changes only when the day does. The next date then moves to the new day in the
/// month of the old `next_due`, the first month not yet posted, so a month is never posted twice. If that day has already passed, it moves to
/// the next due date from today, so nothing is back-posted (DECISIONS D34).
final class EditBill implements UseCase<RecurringRule, EditBillParams> {
  const EditBill({required this._recurring, required this._clock});

  final RecurringRepository _recurring;
  final Clock _clock;

  /// Returns [Right] with the updated rule, or [Left] with a `BillValidator` failure (nothing
  /// saved), `RuleNotFoundFailure` when the bill was deleted, or `DatabaseFailure`.
  @override
  TaskEither<Failure, RecurringRule> call(EditBillParams params) =>
      TaskEither<Failure, BillInput>.fromEither(BillValidator.validate(params.input))
          .flatMap((BillInput input) => _recurring.update(_edited(params.rule, input)));

  RecurringRule _edited(RecurringRule rule, BillInput input) {
    // why: an edit that keeps the day must not touch the schedule, or a stale next_due (the
    // engine hasn't run yet) would skip a month that is still owed (FR-SE-1 AC-4).
    if (input.dueDay == rule.schedule.anchor.day) {
      return rule.copyWith(label: input.label, amount: input.amount, icon: input.icon);
    }
    final CalendarDate today = _clock.today();
    final Schedule schedule =
        Schedule(frequency: Frequency.monthly, anchor: RecurringSchedule.monthlyAnchor(input.dueDay, near: today));
    return rule.copyWith(
      label: input.label,
      amount: input.amount,
      schedule: schedule,
      nextDue: _nextDue(schedule, rule.nextDue, today),
      icon: input.icon,
    );
  }

  static CalendarDate _nextDue(Schedule schedule, CalendarDate oldNextDue, CalendarDate today) {
    final CalendarDate sameMonth =
        RecurringSchedule.firstOnOrAfter(schedule, CalendarDate(oldNextDue.year, oldNextDue.month, 1));
    return sameMonth.isBefore(today) ? RecurringSchedule.firstOnOrAfter(schedule, today) : sameMonth;
  }
}
