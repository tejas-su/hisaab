import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import 'category_spend.dart';
import 'insight.dart';
import 'pace_series.dart';

/// Everything Spends shows for one cycle (SPEC FR-SP-1, -3, -4, -5).
final class SpendsOverview extends Equatable {
  const SpendsOverview({
    required this.cycle,
    required this.previous,
    required this.cyclesBack,
    required this.canGoBack,
    required this.spent,
    required this.budget,
    required this.pace,
    required this.rows,
    required this.insights,
  });

  final PayCycle cycle;

  /// The cycle before [cycle], which insights compare against (BR-14 #1, #4).
  final PayCycle previous;

  /// 0 for the current cycle, 1 for the one before, and so on.
  final int cyclesBack;

  /// Whether an earlier cycle has anything to show.
  final bool canGoBack;

  /// *Spent* in the cycle so far.
  final Money spent;

  /// `I − K`: what the cycle had to spend.
  final Money budget;

  /// The pace chart; [None] when there was no money to spend (no steady line).
  final Option<PaceSeries> pace;

  /// *Where it went*, biggest first; empty when nothing was spent.
  final List<CategorySpend> rows;

  /// At most 3, in BR-14 priority order.
  final List<Insight> insights;

  /// The current cycle has no Next.
  bool get isCurrent => cyclesBack == 0;

  /// Nothing was spent in the cycle (the empty state).
  bool get isEmpty => rows.isEmpty;

  @override
  List<Object?> get props => <Object?>[cycle, previous, cyclesBack, canGoBack, spent, budget, pace, rows, insights];
}
