import 'package:equatable/equatable.dart';

import '../../../core/time/month_start.dart';
import '../../../core/time/pay_switch.dart';

/// The ledger-owned settings that change the cycle maths (DECISIONS D20). Keep-aside is no
/// longer a setting: `K` is computed from savings (D120).
final class BudgetSettings extends Equatable {
  const BudgetSettings({this.monthStart = MonthStart.payday, this.paySwitches = const <PaySwitch>[]});

  /// Whether cycles follow payday (default) or the calendar month (SPEC BR-1).
  final MonthStart monthStart;

  /// The earlier pay rules, oldest first, so a changed payday bridges its cycle (BR-1a, D140).
  final List<PaySwitch> paySwitches;

  @override
  List<Object?> get props => <Object?>[monthStart, paySwitches];
}
