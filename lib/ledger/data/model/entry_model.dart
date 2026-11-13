import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';

/// A row of the `transactions` table, with every column as stored.
final class EntryModel extends Equatable {
  const EntryModel({
    this.id,
    required this.amountMinor,
    required this.currency,
    required this.kind,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
    this.recurringId,
    this.savingId,
  });

  /// Reads a `transactions` row.
  ///
  /// Returns [Right] with the model, or [Left] with [InvalidDataFailure] for a missing or
  /// wrongly typed column.
  static Either<Failure, EntryModel> fromRow(Map<String, Object?> row) => readRow(
        Tables.transactions,
        () => EntryModel(
          id: row.intAt(TransactionColumns.id),
          amountMinor: row.intAt(TransactionColumns.amountMinor),
          currency: row.stringAt(TransactionColumns.currency),
          kind: row.stringAt(TransactionColumns.kind),
          categoryId: row.intAt(TransactionColumns.categoryId),
          date: row.stringAt(TransactionColumns.date),
          note: row.stringOrNullAt(TransactionColumns.note),
          recurringId: row.intOrNullAt(TransactionColumns.recurringId),
          createdAt: row.stringAt(TransactionColumns.createdAt),
          savingId: row.intOrNullAt(TransactionColumns.savingId),
        ),
      );

  /// Null before the row is inserted.
  final int? id;
  final int amountMinor;

  /// ISO currency code.
  final String currency;

  /// [EntryKindValues] value.
  final String kind;
  final int categoryId;

  /// `YYYY-MM-DD`.
  final String date;
  final String? note;
  final int? recurringId;

  /// `saving_id`: the saving a *Used* entry was paid from.
  final int? savingId;

  /// ISO timestamp of the insert.
  final String createdAt;

  /// The row to insert or update; omits `id` when it is null so SQLite assigns one, and omits
  /// `saving_id` when it is null, as only a *Used* entry has one.
  Map<String, Object?> toRow() => <String, Object?>{
        if (id != null) TransactionColumns.id: id,
        TransactionColumns.amountMinor: amountMinor,
        TransactionColumns.currency: currency,
        TransactionColumns.kind: kind,
        TransactionColumns.categoryId: categoryId,
        TransactionColumns.date: date,
        TransactionColumns.note: note,
        TransactionColumns.recurringId: recurringId,
        TransactionColumns.createdAt: createdAt,
        if (savingId != null) TransactionColumns.savingId: savingId,
      };

  @override
  List<Object?> get props => <Object?>[id, amountMinor, currency, kind, categoryId, date, note, recurringId, createdAt, savingId];
}
