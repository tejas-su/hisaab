import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../ledger/ledger.dart';
import 'entities/afford_answer.dart';
import 'entities/afford_context.dart';

/// When a *Not yet* answer's saving would be done (SPEC BR-24 "Done by"), counted as BR-23 counts
/// a saving's estimate, so the answer and the Savings row never disagree.
abstract final class AffordDoneBy {
  /// The date of the put-in that reaches `answer.need` at `answer.spare` a month, starting from the
  /// saving's first `next_due` on or after [today].
  ///
  /// Returns [None] when there is nothing to save for or nothing spare (*Yes, you can*, the days
  /// already full, no history), and past BR-23's 120 put-ins. *Yes, without a loan* gets a date
  /// too, for its *Save up* row under *Other ways*.
  static Option<CalendarDate> of(
    AffordAnswer answer,
    AffordContext context,
    CalendarDate today,
  ) {
    if (answer.need.isZero || answer.spare.isZero) {
      return const Option<CalendarDate>.none();
    }
    final TargetProgress progress = SavingTarget.progress(
      target: answer.need,
      setAside: Money.zero,
      saving: _predicted(answer.spare, context, today),
    );
    return switch (progress) {
      TargetEstimate(:final CalendarDate doneOn) => Option<CalendarDate>.of(
        doneOn,
      ),
      TargetReached() || TargetFar() => const Option<CalendarDate>.none(),
    };
  }

  // why: a new saving goes in on the day after payday (D220); a re-checked one keeps its own day
  // and its next date (D221). Either way the first put-in is never before today.
  static RecurringRule _predicted(
    Money monthly,
    AffordContext context,
    CalendarDate today,
  ) => context.existingSaving.match(
    () {
      final Schedule schedule = Schedule(
        frequency: Frequency.monthly,
        anchor: RecurringSchedule.monthlyAnchor(
          context.nextCycle.start.addDays(1).day,
          near: today,
        ),
      );
      return RecurringRule(
        id: 0,
        label: '',
        amount: monthly,
        kind: EntryKind.saved,
        categoryId: 0,
        schedule: schedule,
        nextDue: RecurringSchedule.firstOnOrAfter(schedule, today),
      );
    },
    (RecurringRule saving) {
      final CalendarDate first = RecurringSchedule.firstOnOrAfter(
        saving.schedule,
        today,
      );
      return saving.copyWith(
        amount: monthly,
        nextDue: saving.nextDue.isBefore(first) ? first : saving.nextDue,
      );
    },
  );
}
