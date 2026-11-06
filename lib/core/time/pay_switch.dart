import 'package:equatable/equatable.dart';

import 'calendar_date.dart';
import 'pay_rule.dart';

/// A change of when the income comes (SPEC BR-1a, DECISIONS D140): on [on] the pay rule stopped
/// being [from]. The rule it became is the next switch's [from], or the current rule.
final class PaySwitch extends Equatable {
  const PaySwitch({required this.on, required this.from});

  /// The day the change was made.
  final CalendarDate on;

  /// The pay rule before the change.
  final PayRule from;

  @override
  List<Object?> get props => <Object?>[on, from];
}
