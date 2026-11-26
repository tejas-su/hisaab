import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../due_amounts.dart';
import '../entities/due_soon_bill.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../entities/saving_totals.dart';
import '../recurring_schedule.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import '../saving_caps.dart';
import '../set_aside.dart';

/// Finds the soonest unposted bill or saving occurrence within the next [window] days (SPEC BR-9, D120).
///
/// A saving with a target is nudged at what the engine will post: a reached saving is skipped and
/// the last put-in shows its gap (BR-23, D213).
final class GetDueSoonBill implements UseCase<Option<DueSoonBill>, NoParams> {
  const GetDueSoonBill({
    required this._recurring,
    required this._ledger,
    required this._clock,
  });

  /// How many days ahead a bill counts as "due soon".
  static const int window = 5;

  final RecurringRepository _recurring;
  final LedgerRepository _ledger;
  final Clock _clock;

  /// Returns [Right] with the soonest bill (the first rule on a tie), [None] when nothing is due
  /// within [window] days, or [Left] with `DatabaseFailure` when the rules or the saving totals
  /// can't be read.
  @override
  TaskEither<Failure, Option<DueSoonBill>> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return _recurring.activeRules().flatMap(
      (List<RecurringRule> rules) => _ledger.savingTotals().map(
        (SavingTotals totals) => _soonest(rules, totals, today),
      ),
    );
  }

  static Option<DueSoonBill> _soonest(
    List<RecurringRule> rules,
    SavingTotals totals,
    CalendarDate today,
  ) {
    final Iterable<DueSoonBill> soon = rules
        .where(
          (RecurringRule rule) =>
              rule.kind == EntryKind.spent || rule.kind == EntryKind.saved,
        )
        .map((RecurringRule rule) => _nextOf(rule, totals, today))
        .where(
          (DueSoonBill bill) => bill.daysAway <= window && !_reached(bill),
        );
    return Option<DueSoonBill>.fromNullable(
      soon.fold<DueSoonBill?>(
        null,
        (DueSoonBill? best, DueSoonBill bill) =>
            best == null || bill.daysAway < best.daysAway ? bill : best,
      ),
    );
  }

  // why: the next put-in is the first still to post, so the set aside now is all it can add to.
  static DueSoonBill _nextOf(
    RecurringRule rule,
    SavingTotals totals,
    CalendarDate today,
  ) {
    final CalendarDate due = RecurringSchedule.firstUnpostedAfter(
      rule.schedule,
      rule.nextDue,
      today: today,
    );
    final Money amount = rule.kind == EntryKind.saved
        ? _cappedPutIn(rule, totals, due)
        : rule.amount;
    return DueSoonBill(
      rule: rule,
      dueDate: due,
      daysAway: today.daysUntil(due),
      amount: amount,
    );
  }

  // why: a reached saving posts nothing (D213), so it is never nudged and the next bill wins.
  static bool _reached(DueSoonBill bill) =>
      bill.rule.kind == EntryKind.saved && bill.amount == Money.zero;

  static Money _cappedPutIn(
    RecurringRule saving,
    SavingTotals totals,
    CalendarDate due,
  ) {
    final ({Money putIn, Money used}) saved =
        totals.bySaving[saving.id] ?? (putIn: Money.zero, used: Money.zero);
    return SavingCaps.capped(
      saving,
      <DatedAmount>[(date: due, amount: saving.amount)],
      SetAside.of(saved.putIn, saved.used),
    ).fold(Money.zero, (Money total, DatedAmount item) => total + item.amount);
  }
}
