import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../ledger/ledger.dart';

/// The ledger data a prompt is built from, loaded once for the longest period (SPEC BR-15).
final class PromptInput extends Equatable {
  const PromptInput({
    required this.cycles,
    required this.today,
    required this.incomeRule,
    required this.payRule,
    required this.bills,
    required this.categories,
    required this.entries,
    this.summary = const Option<CycleSummary>.none(),
    this.savings = const <RecurringRule>[],
  });

  /// The cycle Spends was showing, then the two before it: always 3, newest first.
  final List<PayCycle> cycles;

  final CalendarDate today;

  /// The salary rule; [None] when income has no rule.
  final Option<RecurringRule> incomeRule;

  final PayRule payRule;

  /// Active *Spent* rules, such as rent.
  final List<RecurringRule> bills;

  final List<Category> categories;

  /// Entries from the oldest cycle's start to the newest cycle's end or today, in any order.
  final List<Entry> entries;

  /// Home's summary of today (SPEC BR-3 to BR-7); [None] unless the newest cycle holds today.
  final Option<CycleSummary> summary;

  /// Active *Saved* rules, such as an RD (D120); empty when nothing is saved.
  final List<RecurringRule> savings;

  /// Whether the on-track goal is offered (FR-AI-1): the shown cycle holds today, so the forecast
  /// has a payday or a month end to reach (DECISIONS D117, amending D72).
  bool get offersOnTrack => cycles.first.contains(today);

  /// Whether today's cycle ends at month end, so the goal asks *Will my money last the month?*;
  /// false for a past cycle, which has no summary (D117).
  bool get endsAtMonthEnd => summary.match(() => false, (CycleSummary summary) => summary.endsAtMonthEnd);

  @override
  List<Object?> get props => <Object?>[cycles, today, incomeRule, payRule, bills, categories, entries, summary, savings];
}
