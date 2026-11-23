import 'package:equatable/equatable.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import 'entities/recurring_rule.dart';
import 'recurring_schedule.dart';

/// How far a saving is from its target (SPEC BR-23).
sealed class TargetProgress extends Equatable {
  const TargetProgress();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The set-aside amount already covers the target.
final class TargetReached extends TargetProgress {
  const TargetReached();
}

/// The target is reached by the put-in on [doneOn].
final class TargetEstimate extends TargetProgress {
  const TargetEstimate(this.doneOn);

  final CalendarDate doneOn;

  @override
  List<Object?> get props => <Object?>[doneOn];
}

/// The target needs more than [SavingTarget.maxPutIns] put-ins, so no date is promised.
final class TargetFar extends TargetProgress {
  const TargetFar();
}

/// Pure maths for a saving's target (SPEC BR-23).
abstract final class SavingTarget {
  /// The most put-ins an estimate is given for; beyond it the result is [TargetFar].
  static const int maxPutIns = 120;

  /// Works out when [saving] reaches [target] given [setAside].
  ///
  /// With `n = ceil((target − setAside) / saving.amount)` in paise, returns [TargetReached] when
  /// nothing is left to save, [TargetFar] when `n` exceeds [maxPutIns], and otherwise a
  /// [TargetEstimate] on the n-th put-in date counted from `saving.nextDue`.
  ///
  /// `saving.amount` is at least ₹1, so the division is safe.
  static TargetProgress progress({required Money target, required Money setAside, required RecurringRule saving}) {
    final int gap = target.amountMinor - setAside.amountMinor;
    if (gap <= 0) return const TargetReached();
    final int each = saving.amount.amountMinor;
    final int putIns = (gap + each - 1) ~/ each;
    if (putIns > maxPutIns) return const TargetFar();
    return TargetEstimate(_nthPutIn(saving, putIns));
  }

  static CalendarDate _nthPutIn(RecurringRule saving, int putIns) {
    CalendarDate date = saving.nextDue;
    for (int step = 1; step < putIns; step++) {
      date = RecurringSchedule.next(saving.schedule, date);
    }
    return date;
  }
}
