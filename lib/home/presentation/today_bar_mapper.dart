import 'dart:math' as math;

import '../../core/widgets/today_bar/today_bar_data.dart';
import '../../ledger/ledger.dart';

/// Maps a [CycleSummary] and today's *Spent* entries to today's bar (SPEC BR-6).
abstract final class TodayBarMapper {
  /// [spends] are today's *Spent* entries, oldest first; [nameOf] names each one's category.
  ///
  /// The span is `max(A, S_today)`, so the bar is today's share until it is overspent; then it
  /// spans what was spent and the tick marks the share.
  static TodayBarData of(CycleSummary summary, List<Entry> spends, {required String Function(Entry) nameOf}) {
    final int share = summary.todayShare.amountMinor;
    final int spent = summary.spentToday.amountMinor;
    final int span = math.max(share, spent);
    if (span == 0) {
      return TodayBarData(style: _style(summary.state));
    }
    return TodayBarData(
      style: _style(summary.state),
      left: math.max(0, share - spent) / span,
      bites: <TodayBite>[for (final Entry e in spends) TodayBite(share: e.amount.amountMinor / span, label: nameOf(e))],
      tick: spent > share ? share / span : null,
    );
  }

  static TodayBarStyle _style(CycleState state) => switch (state) {
        OnTrack() => TodayBarStyle.onTrack,
        SlowDown() => TodayBarStyle.slowDown,
        OverToday() || OverCycle() || NoIncome() => TodayBarStyle.over,
      };
}
