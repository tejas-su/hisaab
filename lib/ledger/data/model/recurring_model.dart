import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';

/// A row of the `recurring` table (`freq` is [frequency]; the flags are stored as 0/1).
final class RecurringModel extends Equatable {
  const RecurringModel({
    this.id,
    required this.label,
    required this.amountMinor,
    required this.currency,
    required this.kind,
    required this.categoryId,
    required this.frequency,
    required this.anchorDate,
    required this.lastDayOfMonth,
    required this.nextDue,
    required this.isIncomeSource,
    this.icon,
  });

  /// Reads a `recurring` row.
  ///
  /// Returns [Right] with the model, or [Left] with [InvalidDataFailure] for a bad column.
  static Either<Failure, RecurringModel> fromRow(Map<String, Object?> row) => readRow(
        Tables.recurring,
        () => RecurringModel(
          id: row.intAt(RecurringColumns.id),
          label: row.stringAt(RecurringColumns.label),
          amountMinor: row.intAt(RecurringColumns.amountMinor),
          currency: row.stringAt(RecurringColumns.currency),
          kind: row.stringAt(RecurringColumns.kind),
          categoryId: row.intAt(RecurringColumns.categoryId),
          frequency: row.stringAt(RecurringColumns.frequency),
          anchorDate: row.stringAt(RecurringColumns.anchorDate),
          lastDayOfMonth: row.intAt(RecurringColumns.lastDayOfMonth) == 1,
          nextDue: row.stringAt(RecurringColumns.nextDue),
          isIncomeSource: row.intAt(RecurringColumns.isIncomeSource) == 1,
          icon: row.stringOrNullAt(RecurringColumns.icon),
        ),
      );

  final int? id;
  final String label;
  final int amountMinor;
  final String currency;
  final String kind;
  final int categoryId;

  /// [FrequencyValues] value.
  final String frequency;
  final String anchorDate;
  final bool lastDayOfMonth;
  final String nextDue;
  final bool isIncomeSource;

  /// The picked bill icon's stored value, or null when the icon follows the name.
  final String? icon;

  /// The row to insert; omits `id` when null. New rules are always active.
  Map<String, Object?> toRow() => <String, Object?>{
        if (id != null) RecurringColumns.id: id,
        RecurringColumns.label: label,
        RecurringColumns.amountMinor: amountMinor,
        RecurringColumns.currency: currency,
        RecurringColumns.kind: kind,
        RecurringColumns.categoryId: categoryId,
        RecurringColumns.frequency: frequency,
        RecurringColumns.anchorDate: anchorDate,
        RecurringColumns.lastDayOfMonth: lastDayOfMonth ? 1 : 0,
        RecurringColumns.nextDue: nextDue,
        RecurringColumns.active: 1,
        RecurringColumns.isIncomeSource: isIncomeSource ? 1 : 0,
        RecurringColumns.icon: icon,
      };

  @override
  List<Object?> get props =>
      <Object?>[id, label, amountMinor, currency, kind, categoryId, frequency, anchorDate, lastDayOfMonth, nextDue, isIncomeSource, icon];
}
