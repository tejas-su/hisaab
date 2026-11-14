import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import 'category_detail.dart';
import 'category_spend.dart';
import 'cycle_bar.dart';
import 'insight.dart';
import 'money_split.dart';
import 'month_story.dart';
import 'pace_series.dart';
import 'spends_comparison.dart';

/// Everything Spends shows for one cycle (SPEC FR-SP-1, -3, -4, -5).
final class SpendsOverview extends Equatable {
  const SpendsOverview({
    required this.cycle,
    required this.previous,
    required this.cyclesBack,
    required this.canGoBack,
    required this.spent,
    required this.budget,
    required this.saved,
    this.notLogged = Money.zero,
    required this.pace,
    required this.rows,
    required this.insights,
    this.story = const Option<MonthStory>.none(),
    this.showsStoryRow = false,
    this.split = MoneySplit.empty,
    this.comparison = const Option<SpendsComparison>.none(),
    this.details = const <int, CategoryDetail>{},
    this.strip = const Option<MonthsStrip>.none(),
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

  /// *Saved* entries in the cycle up to the day it is seen from; never part of [spent] (D120).
  final Money saved;

  /// *Spent* *Not logged* fixes in the cycle up to the day it is seen from: its own part of the
  /// Spends line, never inside [spent] (BR-18, FR-SP-4a). A *Got* fix is not here.
  final Money notLogged;

  /// The pace chart; [None] when there was no money to spend (no steady line).
  final Option<PaceSeries> pace;

  /// *Where it went*, biggest first; empty when nothing was spent.
  final List<CategorySpend> rows;

  /// At most 3, in BR-14 priority order.
  final List<Insight> insights;

  /// A finished cycle's month story, behind the card below Ask AI; [None] on the current cycle
  /// and on a cycle BR-20 gives none (FR-SP-7 AC-1).
  final Option<MonthStory> story;

  /// Whether the current cycle shows the slim row to the cycle before's story: days 1 to 7, when
  /// that cycle has one (FR-SP-7 AC-2).
  final bool showsStoryRow;

  /// The split card's numbers (FR-SP-4b).
  final MoneySplit split;

  /// The pace card's comparison line (FR-SP-3a); [None] without a fully tracked cycle before.
  final Option<SpendsComparison> comparison;

  /// What each row of *Where it went* shows when opened, by category id (FR-SP-4 AC-R2).
  final Map<int, CategoryDetail> details;

  /// The months strip (FR-SP-8); [None] until BR-21 shows it.
  final Option<MonthsStrip> strip;

  /// The current cycle has no Next.
  bool get isCurrent => cyclesBack == 0;

  /// Nothing was spent in the cycle (the empty state).
  bool get isEmpty => rows.isEmpty;

  @override
  List<Object?> get props => <Object?>[cycle, previous, cyclesBack, canGoBack, spent, budget, saved, notLogged, pace, rows, insights, story, showsStoryRow, split, comparison, details, strip];
}
