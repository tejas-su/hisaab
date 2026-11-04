import 'package:equatable/equatable.dart';

/// What one weekday column of [WeekBarsData] shows (SPEC BR-6a).
enum WeekBarKind {
  /// A day already over: its spending, in the past-day colour.
  past,

  /// Today: its spending in marigold.
  today,

  /// A day still to come in this cycle: a short idle stub.
  future,

  /// Before the cycle started, or from payday on: nothing is drawn.
  none,
}

/// One weekday column; heights are shares of the tallest value in the week, 0–1.
final class WeekBar extends Equatable {
  const WeekBar({required this.kind, this.spent = 0, this.share = 0});

  final WeekBarKind kind;

  /// The day's spending as a share of the tallest value.
  final double spent;

  /// Where the day's share tick sits, as a share of the tallest value.
  final double share;

  /// Spending above the share tick, drawn hatched.
  bool get isOver => spent > share;

  @override
  List<Object?> get props => <Object?>[kind, spent, share];
}

/// The seven columns of the hero's *This week* bars, Monday first (SPEC BR-6a).
final class WeekBarsData extends Equatable {
  const WeekBarsData({required this.bars, required this.todayIndex});

  /// Exactly seven, Monday to Sunday.
  final List<WeekBar> bars;

  /// Today's column, 0 (Monday) to 6; the bars grow outward from it.
  final int todayIndex;

  @override
  List<Object?> get props => <Object?>[bars, todayIndex];
}
