import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';
import 'recurring_rule.dart';

/// One due date of a recurring [rule], waiting to be posted as an entry (SPEC BR-9).
final class Occurrence extends Equatable {
  const Occurrence({required this.rule, required this.date});

  final RecurringRule rule;
  final CalendarDate date;

  @override
  List<Object?> get props => <Object?>[rule, date];
}
