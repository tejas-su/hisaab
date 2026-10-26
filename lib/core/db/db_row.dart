import 'package:fpdart/fpdart.dart';

import '../errors/failure.dart';

/// Typed reads of a sqflite row, which is `Map<String, Object?>` and can drift from the schema.
///
/// Each read narrows with `is` and throws [FormatException] naming the column on a mismatch;
/// models call these inside `Either.tryCatch` to turn a bad row into [InvalidDataFailure].
extension DbRowExtensions on Map<String, Object?> {
  /// The non-null integer in [column].
  int intAt(String column) => switch (this[column]) {
        final int value => value,
        final Object? other => throw FormatException('Column "$column" is not an int: $other'),
      };

  /// The integer in [column], or null.
  int? intOrNullAt(String column) => this[column] == null ? null : intAt(column);

  /// The non-null text in [column].
  String stringAt(String column) => switch (this[column]) {
        final String value => value,
        final Object? other => throw FormatException('Column "$column" is not text: $other'),
      };

  /// The text in [column], or null.
  String? stringOrNullAt(String column) => this[column] == null ? null : stringAt(column);
}

/// Reads a model from a row with [read], turning a [FormatException] into [InvalidDataFailure].
///
/// Returns [Right] with the model, or [Left] with [InvalidDataFailure] naming [table].
Either<Failure, T> readRow<T>(String table, T Function() read) => Either<Failure, T>.tryCatch(
      read,
      (Object error, StackTrace _) => InvalidDataFailure('Bad $table row: $error'),
    );

/// Thrown by a data source when a stored row is unreadable; [dbTask] returns its [failure].
final class RowFailureException implements Exception {
  const RowFailureException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}

/// Returns the model in [result], or throws [RowFailureException] so [dbTask] reports it.
T requireRow<T>(Either<Failure, T> result) =>
    result.getOrElse((Failure failure) => throw RowFailureException(failure));

/// Runs a data source call as a [TaskEither].
///
/// Returns [Right] with its result, or [Left] with the row's failure for a
/// [RowFailureException] and [DatabaseFailure] for anything else sqflite threw.
TaskEither<Failure, T> dbTask<T>(Future<T> Function() run) => TaskEither<Failure, T>.tryCatch(
      run,
      (Object error, StackTrace _) => error is RowFailureException ? error.failure : DatabaseFailure(error),
    );
