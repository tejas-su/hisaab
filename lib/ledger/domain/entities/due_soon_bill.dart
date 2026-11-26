import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'recurring_rule.dart';

/// The next fixed bill about to go out, for Home's due-soon nudge (SPEC BR-9, FR-HO-3).
final class DueSoonBill extends Equatable {
  /// A bill due on [dueDate], [daysAway] days from today, going out at [amount] (the rule's own
  /// amount when not given).
  DueSoonBill({
    required this.rule,
    required this.dueDate,
    required this.daysAway,
    Money? amount,
  }) : amount = amount ?? rule.amount;

  /// The bill's rule, which Home opens in the bill sheet (D118).
  final RecurringRule rule;
  final CalendarDate dueDate;

  /// Whole days from today to [dueDate]; 1 means tomorrow.
  final int daysAway;

  /// The rule's name, e.g. "Electricity".
  String get label => rule.label;

  /// What goes out: the rule's amount, or a saving's last put-in cut to its target gap (BR-23, D213).
  final Money amount;

  @override
  List<Object?> get props => <Object?>[rule, dueDate, daysAway, amount];
}
