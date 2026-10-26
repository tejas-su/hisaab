import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'entry_kind.dart';
import 'recurring_draft.dart';
import 'schedule.dart';

/// A template that posts an entry on a schedule, such as salary or rent (SPEC BR-9).
final class RecurringRule extends Equatable {
  const RecurringRule({
    required this.id,
    required this.label,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.schedule,
    required this.nextDue,
    this.isIncomeSource = false,
  });

  final int id;

  /// The user-visible name, e.g. "Rent".
  final String label;
  final Money amount;
  final EntryKind kind;
  final int categoryId;
  final Schedule schedule;

  /// The first occurrence not yet posted; only ever moves forward (SPEC E9).
  final CalendarDate nextDue;

  /// True for the salary rule whose schedule defines the pay cycle (DECISIONS D20).
  final bool isIncomeSource;

  /// This rule's fields without its id.
  RecurringDraft get draft => RecurringDraft(
        label: label,
        amount: amount,
        kind: kind,
        categoryId: categoryId,
        schedule: schedule,
        nextDue: nextDue,
        isIncomeSource: isIncomeSource,
      );

  /// Returns a copy with the given fields replaced.
  RecurringRule copyWith({String? label, Money? amount, Schedule? schedule, CalendarDate? nextDue}) => RecurringRule(
        id: id,
        label: label ?? this.label,
        amount: amount ?? this.amount,
        kind: kind,
        categoryId: categoryId,
        schedule: schedule ?? this.schedule,
        nextDue: nextDue ?? this.nextDue,
        isIncomeSource: isIncomeSource,
      );

  @override
  List<Object?> get props => <Object?>[id, label, amount, kind, categoryId, schedule, nextDue, isIncomeSource];
}
