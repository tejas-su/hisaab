import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import 'due_amounts.dart';
import 'entities/recurring_rule.dart';
import 'entities/saving_totals.dart';
import 'set_aside.dart';

/// The one walk that stops a saving with a target at it (SPEC BR-23, D213).
abstract final class SavingCaps {
  /// A saved rule's put-ins still to post after [today] up to the end of [cycle], capped at its gap
  /// from the set aside in [totals].
  static List<DatedAmount> reservedAfter(
    RecurringRule saving,
    SavingTotals totals, {
    required CalendarDate today,
    required PayCycle cycle,
  }) {
    final ({Money putIn, Money used}) saved =
        totals.bySaving[saving.id] ?? (putIn: Money.zero, used: Money.zero);
    return capped(
      saving,
      DueAmounts.datedAfter(
        <RecurringRule>[saving],
        today: today,
        cycle: cycle,
      ),
      SetAside.of(saved.putIn, saved.used),
    );
  }

  /// The part of [due] (a saving's put-ins in date order) that still fits under the saving's target,
  /// given [setAside] now.
  ///
  /// Each date takes the smaller of its amount and what is left of the gap, so the last put-in is
  /// short and later ones are dropped. A saving with no target keeps [due] as it is.
  // why: the engine posts this and Home reserves this, so a reached saving reserves nothing and
  // *I bought it* leaves the hero where it was (D213, AC-T9).
  static List<DatedAmount> capped(
    RecurringRule saving,
    List<DatedAmount> due,
    Money setAside,
  ) {
    final Money? target = saving.target.toNullable();
    if (target == null) {
      return due;
    }
    final (Money, List<DatedAmount>) walked = due.fold(
      (setAside, const <DatedAmount>[]),
      ((Money, List<DatedAmount>) walk, DatedAmount item) {
        final Money gap = target > walk.$1 ? target - walk.$1 : Money.zero;
        final Money posted = gap > item.amount ? item.amount : gap;
        return posted == Money.zero
            ? walk
            : (
                walk.$1 + posted,
                <DatedAmount>[...walk.$2, (date: item.date, amount: posted)],
              );
      },
    );
    return walked.$2;
  }
}
