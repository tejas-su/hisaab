import 'package:equatable/equatable.dart';

/// How today's bar draws what's left; each state has its own shape, so colour is never the only
/// cue (SPEC BR-5, UI_DESIGN §3.3).
enum TodayBarStyle {
  /// Solid marigold yellow.
  onTrack,

  /// The yellow drawn as a marigold outline.
  slowDown,

  /// No yellow; the share tick and a hatch past it (over today and over for the cycle).
  over,
}

/// One *Spent* entry dated today, as a piece of the bar.
final class TodayBite extends Equatable {
  const TodayBite({required this.share, this.label});

  /// The entry's amount as a share of the bar's span, 0–1.
  final double share;

  /// The category name shown under the bite when it fits.
  final String? label;

  @override
  List<Object?> get props => <Object?>[share, label];
}

/// What [TodayBar] draws: today's share as one bar, eaten by today's spends (SPEC BR-6).
final class TodayBarData extends Equatable {
  const TodayBarData({required this.style, this.left = 0, this.bites = const <TodayBite>[], this.tick});

  final TodayBarStyle style;

  /// What's left of today's share, as a share of the span, 0–1, drawn from the start edge.
  final double left;

  /// Today's spends in the order saved; the first sits at the end edge.
  final List<TodayBite> bites;

  /// Where today's share ends when more was spent, as a share of the span; null when not over.
  final double? tick;

  @override
  List<Object?> get props => <Object?>[style, left, bites, tick];
}
