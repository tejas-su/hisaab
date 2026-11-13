import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/suggestion_state_repository.dart';

/// Records that the missed-log line asked about a category today (SPEC BR-17, D172). It writes
/// only `asked_on`, so it never counts as an Undo and never rests a habit. Takes the category id.
final class MarkMissedLogAsked implements UseCase<Unit, int> {
  /// Writes to [_states]; "today" comes from [_clock].
  const MarkMissedLogAsked({required this._states, required this._clock});

  final SuggestionStateRepository _states;
  final Clock _clock;

  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(int categoryId) => _states.markAsked(categoryId, _clock.today());
}
