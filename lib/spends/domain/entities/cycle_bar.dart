import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import 'money_split.dart';

/// One cycle in the months strip (SPEC FR-SP-8): what it spent and saved against what came in.
final class CycleBar extends Equatable {
  const CycleBar({required this.cycle, required this.cyclesBack, required this.split, required this.isRunning, required this.daysLeft});

  final PayCycle cycle;

  /// 0 for the current cycle; *Open* shows this one.
  final int cyclesBack;
  final MoneySplit split;

  /// The cycle holds today.
  final bool isRunning;

  /// Days after today until the cycle ends; 0 for a finished cycle.
  final int daysLeft;

  /// *Spent*, as Spends counts it (BR-20).
  Money get spent => split.bills + split.everyday;
  Money get saved => split.saved;
  Money get income => split.income;
  Money get left => split.left;
  bool get hasIncome => split.hasIncome;

  /// Whether anything was spent or saved.
  bool get hasEntries => !spent.isZero || !saved.isZero;

  @override
  List<Object?> get props => <Object?>[cycle, cyclesBack, split, isRunning, daysLeft];
}

/// The months strip: up to 6 cycles, oldest first, ending at the cycle shown (SPEC BR-21, FR-SP-8).
final class MonthsStrip extends Equatable {
  const MonthsStrip(this.bars);

  final List<CycleBar> bars;

  /// Finished cycles with money in, which the summary counts.
  int get counted => bars.where((CycleBar b) => !b.isRunning && b.hasIncome).length;

  /// Of [counted], those with money left over.
  int get leftOver => bars.where((CycleBar b) => !b.isRunning && b.hasIncome && b.left > Money.zero).length;

  @override
  List<Object?> get props => <Object?>[bars];
}
