import 'package:equatable/equatable.dart';

/// How the days rail draws today's dot, and whether the later dots are outlined (SPEC BR-5).
enum DaysRailStyle {
  /// Today's dot solid marigold.
  onTrack,

  /// Today's dot a marigold ring.
  slowDown,

  /// Today's dot hatched.
  overToday,

  /// Today's dot hatched and every later dot outlined.
  overCycle,
}

/// What [DaysRail] draws: one dot per day left, today first (SPEC BR-6).
final class DaysRailData extends Equatable {
  const DaysRailData({required this.count, required this.style});

  /// Days left including today; at least 1.
  final int count;
  final DaysRailStyle style;

  @override
  List<Object?> get props => <Object?>[count, style];
}
