import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/nudge_state.dart';

/// Reads and writes what the daily nudge remembers: armed time, ignored streak and rest (SPEC BR-22.12).
abstract interface class NudgeStateRepository {
  /// Loads the state of every nudge that has one, by category id (0 is the general nudge).
  ///
  /// Returns [Right] with the states (possibly empty), or [Left] with `DatabaseFailure`, or
  /// `InvalidDataFailure` for an unreadable row.
  TaskEither<Failure, Map<int, NudgeState>> all();

  /// Stores [state], replacing the one its category already has.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> put(NudgeState state);

  /// Removes every state.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> clear();
}
