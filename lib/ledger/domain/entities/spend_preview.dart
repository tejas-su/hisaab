import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';

/// What a typed amount would do to today, shown under the Add keypad (SPEC FR-AD-3).
sealed class SpendPreview extends Equatable {
  const SpendPreview();
}

/// The amount fits; [left] of today's share would remain.
final class FitsToday extends SpendPreview {
  const FitsToday(this.left);

  final Money left;

  @override
  List<Object?> get props => <Object?>[left];
}

/// The amount goes [over] today's share; later days would get [tomorrow] each.
final class OverTodayShare extends SpendPreview {
  const OverTodayShare({required this.over, required this.tomorrow});

  final Money over;

  /// [None] on the cycle's last day.
  final Option<Money> tomorrow;

  @override
  List<Object?> get props => <Object?>[over, tomorrow];
}
