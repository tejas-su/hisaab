import 'package:equatable/equatable.dart';

/// The words the pace chart paints beside its lines (FR-SP-3, D133).
final class PaceChartWords extends Equatable {
  const PaceChartWords({this.gap, this.forecast});

  /// Beside today's point: "₹7,042 under" or "₹1,958 over"; null when today isn't shown.
  final String? gap;

  /// At the forecast's end: "about ₹9,300 spare" or "runs out 1 Nov"; null without a forecast.
  final String? forecast;

  @override
  List<Object?> get props => <Object?>[gap, forecast];
}
