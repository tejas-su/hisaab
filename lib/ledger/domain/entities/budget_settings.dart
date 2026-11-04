import 'package:equatable/equatable.dart';

import '../../../core/time/month_start.dart';

/// The ledger-owned settings that change the cycle maths (DECISIONS D20). Keep-aside is no
/// longer a setting: `K` is computed from savings (D120).
final class BudgetSettings extends Equatable {
  const BudgetSettings({this.monthStart = MonthStart.payday});

  /// Whether cycles follow payday (default) or the calendar month (SPEC BR-1).
  final MonthStart monthStart;

  @override
  List<Object?> get props => <Object?>[monthStart];
}
