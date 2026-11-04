import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'recurring_rule.dart';

/// The next fixed bill about to go out, for Home's due-soon nudge (SPEC BR-9, FR-HO-3).
final class DueSoonBill extends Equatable {
  const DueSoonBill({required this.rule, required this.dueDate, required this.daysAway});

  /// The bill's rule, which Home opens in the bill sheet (D118).
  final RecurringRule rule;
  final CalendarDate dueDate;

  /// Whole days from today to [dueDate]; 1 means tomorrow.
  final int daysAway;

  /// The rule's name, e.g. "Electricity".
  String get label => rule.label;
  Money get amount => rule.amount;

  @override
  List<Object?> get props => <Object?>[rule, dueDate, daysAway];
}
