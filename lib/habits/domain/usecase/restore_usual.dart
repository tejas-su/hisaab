import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/forgotten_usual.dart';
import '../repository/suggestion_state_repository.dart';

/// Undoes a *Forget*: the category's state is what it was before, so its habit comes back
/// (SPEC BR-17, E68).
final class RestoreUsual implements UseCase<Unit, ForgottenUsual> {
  /// Writes to [_states].
  const RestoreUsual({required this._states});

  final SuggestionStateRepository _states;

  /// Puts back the state [forgotten] replaced, or removes the category's state when it had none.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(ForgottenUsual forgotten) =>
      forgotten.previous.match(() => _states.remove(forgotten.categoryId), _states.put);
}
