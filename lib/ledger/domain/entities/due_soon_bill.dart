import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';

/// The next fixed bill about to go out, for Home's due-soon nudge (SPEC BR-9, FR-HO-3).
final class DueSoonBill extends Equatable {
  const DueSoonBill({required this.label, required this.amount, required this.dueDate, required this.daysAway});

  /// The rule's name, e.g. "Electricity".
  final String label;
  final Money amount;
  final CalendarDate dueDate;

  /// Whole days from today to [dueDate]; 1 means tomorrow.
  final int daysAway;

  @override
  List<Object?> get props => <Object?>[label, amount, dueDate, daysAway];
}
