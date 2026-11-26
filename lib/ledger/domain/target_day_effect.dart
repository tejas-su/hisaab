import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';

import '../../core/money/money.dart';
import 'due_amounts.dart';
import 'entities/cycle_summary.dart';
import 'entities/recurring_rule.dart';
import 'entities/saving_totals.dart';
import 'safe_to_spend.dart';
import 'saving_caps.dart';

/// What a saving's target does to today's share (SPEC BR-23, owner 2026-11-26).
///
/// A target caps the saving's put-ins still due this cycle at its gap (D213), so it can free or
/// hold back money for the days left. [summary] is today's as it stands, with [saving]'s target as
/// stored; [totals] are what each saving has had put in and used.
final class TargetDayEffect extends Equatable {
  const TargetDayEffect({
    required this.summary,
    required this.saving,
    required this.totals,
  });

  final CycleSummary summary;
  final RecurringRule saving;
  final SavingTotals totals;

  /// How today's share would move if [saving]'s target became [target]: above ₹0 it goes up,
  /// below ₹0 it goes down, ₹0 when it stays.
  // why: the share is the pool over the days left, and the target touches only this saving's
  // reserved put-ins, which the pool already takes off; the same SavingCaps walk Home runs.
  Money changeFor(Money target) {
    final Money freed =
        _reserved(saving.target) - _reserved(Option<Money>.of(target));
    return SafeToSpend.shareOfPool(summary.pool + freed, summary.daysLeft) -
        summary.todayShare;
  }

  Money _reserved(Option<Money> target) => SavingCaps.reservedAfter(
    saving.copyWith(target: target),
    totals,
    today: summary.today,
    cycle: summary.cycle,
  ).fold(Money.zero, (Money total, DatedAmount due) => total + due.amount);

  @override
  List<Object?> get props => <Object?>[summary, saving, totals];
}
