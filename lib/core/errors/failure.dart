import 'package:equatable/equatable.dart';

/// Base of every expected error returned as the Left of an `Either`/`TaskEither`.
///
/// Abstract rather than `sealed` so features can add their own subtypes in their
/// `domain/` folders; Dart only allows sealed subtypes in the same library.
abstract class Failure extends Equatable {
  /// Creates a failure with a developer-facing [message] (never shown to users).
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[runtimeType, message];
}

/// A sqflite read or write threw.
final class DatabaseFailure extends Failure {
  /// Wraps the [error] thrown by the database.
  DatabaseFailure(Object error) : super(error.toString());
}

/// Stored data failed validation, e.g. a corrupt backup file or an unknown column value.
final class InvalidDataFailure extends Failure {
  const InvalidDataFailure(super.message);
}
