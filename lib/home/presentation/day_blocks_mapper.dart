import '../../core/money/money.dart';
import '../../core/widgets/day_blocks/day_blocks_data.dart';
import '../../ledger/ledger.dart';

/// Maps a [CycleSummary] to the Day Blocks picture (SPEC BR-6).
abstract final class DayBlocksMapper {
  static const double _shortestLaterBlock = 0.4;

  /// Fullest today's block draws once anything is spent today (D91).
  static const double _fullestAfterSpend = 0.9;

  /// Today's fill is what's left of today's share, capped at 90% once anything is spent so a
  /// small spend still shows; later blocks shrink with tomorrow's share but never below 40% or
  /// above full height.
  static DayBlocksData of(CycleSummary summary) {
    final int share = summary.todayShare.amountMinor;
    final double fullest = summary.spentToday.amountMinor > 0 ? _fullestAfterSpend : 1;
    return DayBlocksData(
      count: summary.daysLeft,
      style: _style(summary.state),
      todayFill: share > 0 ? (summary.safeToday.amountMinor / share).clamp(0, fullest).toDouble() : 0,
      laterHeight: share > 0
          ? summary.tomorrowShare.match(
              () => 1,
              (Money tomorrow) => (tomorrow.amountMinor / share).clamp(_shortestLaterBlock, 1).toDouble(),
            )
          : 1,
    );
  }

  static DayBlocksStyle _style(CycleState state) => switch (state) {
        OnTrack() => DayBlocksStyle.onTrack,
        SlowDown() => DayBlocksStyle.slowDown,
        OverToday() => DayBlocksStyle.overToday,
        OverCycle() || NoIncome() => DayBlocksStyle.overCycle,
      };
}
