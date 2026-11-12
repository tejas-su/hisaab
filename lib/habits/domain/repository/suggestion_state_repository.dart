import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/suggestion_state.dart';

/// Reads and writes each category's *your usual* state: quiet, resting or forgotten (SPEC BR-17).
abstract interface class SuggestionStateRepository {
  /// Loads the state of every category that has one, by category id.
  ///
  /// Returns [Right] with the states (possibly empty), or [Left] with `DatabaseFailure`, or
  /// `InvalidDataFailure` for an unreadable row.
  TaskEither<Failure, Map<int, SuggestionState>> all();

  /// Loads the state of category [categoryId].
  ///
  /// Returns [Right] with the state, or [None] when the category has none; or [Left] with
  /// `DatabaseFailure`, or `InvalidDataFailure` for an unreadable row.
  TaskEither<Failure, Option<SuggestionState>> of(int categoryId);

  /// Stores [state], replacing the one its category already has.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`, also when the category
  /// doesn't exist.
  TaskEither<Failure, Unit> put(SuggestionState state);

  /// Removes the state of category [categoryId]; a category with none is left as it is.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> remove(int categoryId);
}
