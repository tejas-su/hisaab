import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/month_start.dart';

/// The ledger-owned settings that change the cycle maths (DECISIONS D20).
final class BudgetSettings extends Equatable {
  const BudgetSettings({this.monthStart = MonthStart.payday, this.keepAside = Money.zero});

  /// Whether cycles follow payday (default) or the calendar month (SPEC BR-1).
  final MonthStart monthStart;

  /// Money set aside each cycle and never spendable (`K` in SPEC BR-3); zero when off.
  final Money keepAside;

  @override
  List<Object?> get props => <Object?>[monthStart, keepAside];
}
