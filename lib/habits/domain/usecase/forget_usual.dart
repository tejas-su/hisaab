import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/forgotten_usual.dart';
import '../entities/suggestion_state.dart';
import '../repository/suggestion_state_repository.dart';
import '../suggestion_gate.dart';

/// Forgets a category's *your usual*: what was logged before now stops feeding its habit, and it
/// rests for 30 days (SPEC BR-17, FR-SE-2 AC-6). Takes the category id.
final class ForgetUsual implements UseCase<ForgottenUsual, int> {
  /// Reads and writes [_states]; "now" comes from [_clock].
  const ForgetUsual({required this._states, required this._clock});

  final SuggestionStateRepository _states;
  final Clock _clock;

  /// Returns [Right] with the state the category had before, for `RestoreUsual` to put back, or
  /// [Left] with `DatabaseFailure` or `InvalidDataFailure` (nothing is stored).
  @override
  TaskEither<Failure, ForgottenUsual> call(int categoryId) => _states.of(categoryId).flatMap(
        (Option<SuggestionState> previous) => _states
            .put(SuggestionGate.afterForget(previous, categoryId: categoryId, now: _clock.now()))
            .map((Unit _) => ForgottenUsual(categoryId: categoryId, previous: previous)),
      );
}
