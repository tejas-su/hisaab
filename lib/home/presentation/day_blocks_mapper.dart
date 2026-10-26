import '../../core/money/money.dart';
import '../../core/widgets/day_blocks/day_blocks_data.dart';
import '../../ledger/ledger.dart';

/// Maps a [CycleSummary] to the Day Blocks picture (SPEC BR-6).
abstract final class DayBlocksMapper {
  static const double _shortestLaterBlock = 0.4;

  /// Today's fill is what's left of today's share; later blocks shrink with tomorrow's share
  /// but never below 40% or above full height.
  static DayBlocksData of(CycleSummary summary) {
    final int share = summary.todayShare.amountMinor;
    return DayBlocksData(
      count: summary.daysLeft,
      style: _style(summary.state),
      todayFill: share > 0 ? (summary.safeToday.amountMinor / share).clamp(0, 1).toDouble() : 0,
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
