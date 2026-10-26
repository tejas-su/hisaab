import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'entry_kind.dart';
import 'schedule.dart';

/// A recurring rule about to be created, before it has an id (onboarding, Settings).
final class RecurringDraft extends Equatable {
  const RecurringDraft({
    required this.label,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.schedule,
    required this.nextDue,
    this.isIncomeSource = false,
  });

  final String label;
  final Money amount;
  final EntryKind kind;
  final int categoryId;
  final Schedule schedule;

  /// The first date the engine should post.
  final CalendarDate nextDue;
  final bool isIncomeSource;

  @override
  List<Object?> get props => <Object?>[label, amount, kind, categoryId, schedule, nextDue, isIncomeSource];
}
