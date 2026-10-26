import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// How today's money looks, evaluated in SPEC BR-5 order; drives the hero, blocks and words.
sealed class CycleState extends Equatable {
  const CycleState();

  @override
  List<Object?> get props => <Object?>[];
}

/// No income this cycle and no salary rule, so there is nothing to share out (BR-5 #1, E10).
final class NoIncome extends CycleState {
  const NoIncome();
}

/// More was spent than the whole cycle allows; the hero shows ₹0 (BR-5 #2).
final class OverCycle extends CycleState {
  const OverCycle(this.over);

  /// How far past the cycle's money the spending went.
  final Money over;

  @override
  List<Object?> get props => <Object?>[over];
}

/// Today's share is used up; later days get a little less (BR-5 #3).
final class OverToday extends CycleState {
  const OverToday(this.over);

  /// How far past today's share the spending went.
  final Money over;

  @override
  List<Object?> get props => <Object?>[over];
}

/// Under a quarter of today's share is left, or the pace runs out before payday (BR-5 #4).
final class SlowDown extends CycleState {
  const SlowDown();
}

/// Everything is fine (BR-5 #5).
final class OnTrack extends CycleState {
  const OnTrack();
}
