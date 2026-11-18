import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';

/// A row of the `nudge_state` table: what the daily nudge remembers for one category (SPEC BR-22.12).
///
/// `armed_for` is a local ISO instant in the form of `transactions.created_at`; `rest_until` is a
/// `YYYY-MM-DD` day. Category 0 is the general nudge.
final class NudgeStateModel extends Equatable {
  /// Creates the row of category [categoryId]; a column not given is null, the streak 0.
  const NudgeStateModel({required this.categoryId, this.armedFor, this.ignoredStreak = 0, this.restUntil});

  /// Reads a `nudge_state` row.
  ///
  /// Returns [Right] with the model, or [Left] with [InvalidDataFailure] for a bad column.
  static Either<Failure, NudgeStateModel> fromRow(Map<String, Object?> row) => readRow(
        Tables.nudgeState,
        () => NudgeStateModel(
          categoryId: row.intAt(NudgeStateColumns.categoryId),
          armedFor: row.stringOrNullAt(NudgeStateColumns.armedFor),
          ignoredStreak: row.intAt(NudgeStateColumns.ignoredStreak),
          restUntil: row.stringOrNullAt(NudgeStateColumns.restUntil),
        ),
      );

  /// The `category_id` column, also the primary key.
  final int categoryId;

  /// The `armed_for` column.
  final String? armedFor;

  /// The `ignored_streak` column.
  final int ignoredStreak;

  /// The `rest_until` column.
  final String? restUntil;

  /// The row to store, with every column.
  Map<String, Object?> toRow() => <String, Object?>{
        NudgeStateColumns.categoryId: categoryId,
        NudgeStateColumns.armedFor: armedFor,
        NudgeStateColumns.ignoredStreak: ignoredStreak,
        NudgeStateColumns.restUntil: restUntil,
      };

  @override
  List<Object?> get props => <Object?>[categoryId, armedFor, ignoredStreak, restUntil];
}
