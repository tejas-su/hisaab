import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';

/// A row of the `suggestion_state` table: one category's *your usual* state (SPEC BR-17).
///
/// `quiet_on` and `rest_until` are `YYYY-MM-DD` days; `forgotten_at` is a local ISO instant in
/// the form of `transactions.created_at`.
final class SuggestionStateModel extends Equatable {
  /// Creates the row of category [categoryId]; a column not given is null.
  const SuggestionStateModel({required this.categoryId, this.quietOn, this.restUntil, this.forgottenAt});

  /// Reads a `suggestion_state` row.
  ///
  /// Returns [Right] with the model, or [Left] with [InvalidDataFailure] for a bad column.
  static Either<Failure, SuggestionStateModel> fromRow(Map<String, Object?> row) => readRow(
        Tables.suggestionState,
        () => SuggestionStateModel(
          categoryId: row.intAt(SuggestionStateColumns.categoryId),
          quietOn: row.stringOrNullAt(SuggestionStateColumns.quietOn),
          restUntil: row.stringOrNullAt(SuggestionStateColumns.restUntil),
          forgottenAt: row.stringOrNullAt(SuggestionStateColumns.forgottenAt),
        ),
      );

  /// The `category_id` column, also the primary key.
  final int categoryId;

  /// The `quiet_on` column.
  final String? quietOn;

  /// The `rest_until` column.
  final String? restUntil;

  /// The `forgotten_at` column.
  final String? forgottenAt;

  /// The row to store, with every column.
  Map<String, Object?> toRow() => <String, Object?>{
        SuggestionStateColumns.categoryId: categoryId,
        SuggestionStateColumns.quietOn: quietOn,
        SuggestionStateColumns.restUntil: restUntil,
        SuggestionStateColumns.forgottenAt: forgottenAt,
      };

  @override
  List<Object?> get props => <Object?>[categoryId, quietOn, restUntil, forgottenAt];
}
