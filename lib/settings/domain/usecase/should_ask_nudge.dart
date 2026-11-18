import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/app_preferences_repository.dart';

/// Whether to ask "Remind you about this each day?" now: only if it was never answered (SPEC
/// BR-22.8, FR-SE-7 AC-4). The caller runs it only right after the user tapped the Home missed-log
/// line; the tap is the trigger, never a timer.
final class ShouldAskNudge implements UseCase<bool, NoParams> {
  const ShouldAskNudge({required this._preferences});

  final AppPreferencesRepository _preferences;

  /// Returns [Right] with true when it should ask, or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, bool> call(NoParams params) =>
      _preferences.nudgeChoice().map((Option<bool> answered) => answered.isNone());
}
