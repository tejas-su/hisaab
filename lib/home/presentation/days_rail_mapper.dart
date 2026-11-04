import '../../core/widgets/days_rail/days_rail_data.dart';
import '../../ledger/ledger.dart';

/// Maps a [CycleSummary] to the days rail under the hero's chart (SPEC BR-6).
abstract final class DaysRailMapper {
  static DaysRailData of(CycleSummary summary) => DaysRailData(count: summary.daysLeft, style: _style(summary.state));

  static DaysRailStyle _style(CycleState state) => switch (state) {
        OnTrack() => DaysRailStyle.onTrack,
        SlowDown() => DaysRailStyle.slowDown,
        OverToday() => DaysRailStyle.overToday,
        OverCycle() || NoIncome() => DaysRailStyle.overCycle,
      };
}
