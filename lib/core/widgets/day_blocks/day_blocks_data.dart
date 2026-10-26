import 'package:equatable/equatable.dart';

/// How today's block is drawn; each state has its own shape so colour is never the only cue
/// (UI_DESIGN §3.3).
enum DayBlocksStyle {
  /// Solid marigold, draining from the top as money is spent.
  onTrack,

  /// Marigold outline with a thin marigold sliver.
  slowDown,

  /// Hatched and outlined; later blocks visibly shorter.
  overToday,

  /// Every block empty and outlined.
  overCycle,

  /// Onboarding preview: today full marigold, the rest idle.
  preview,
}

/// What [DayBlocks] draws: one block per day left, today first (SPEC BR-6).
final class DayBlocksData extends Equatable {
  const DayBlocksData({required this.count, required this.style, this.todayFill = 1, this.laterHeight = 1});

  /// Days left including today; at least 1.
  final int count;
  final DayBlocksStyle style;

  /// How much of today's block is still marigold, 0–1.
  final double todayFill;

  /// Height of the later blocks as a share of full height, 0.4–1.
  final double laterHeight;

  @override
  List<Object?> get props => <Object?>[count, style, todayFill, laterHeight];
}
