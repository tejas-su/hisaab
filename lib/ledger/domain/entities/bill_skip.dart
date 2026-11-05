import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';

/// "Didn't go out this month": rule [ruleId]'s occurrence on [date] needs no amount (D123).
final class BillSkip extends Equatable {
  const BillSkip({required this.ruleId, required this.date});

  final int ruleId;
  final CalendarDate date;

  @override
  List<Object?> get props => <Object?>[ruleId, date];
}
