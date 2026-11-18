import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/nudges.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/nudge_switch.dart';
import '../repository/app_preferences_repository.dart';

/// Reads the Settings *Daily nudge* switch (SPEC FR-SE-7 AC-1, E122): the user's answer and whether
/// the phone still allows notifications. Never answered reads as no. It never shows a prompt.
final class GetNudgeSwitch implements UseCase<NudgeSwitch, NoParams> {
  const GetNudgeSwitch({required this._preferences, required this._nudges});

  final AppPreferencesRepository _preferences;
  final Nudges _nudges;

  /// Returns [Right] with the [NudgeSwitch], or [Left] with `DatabaseFailure`.
  ///
  /// The stored answer is left alone when notifications are off, so the switch comes back on if
  /// the user allows them again.
  @override
  TaskEither<Failure, NudgeSwitch> call(NoParams params) => _preferences.nudgeChoice().flatMap(
        (Option<bool> choice) => TaskEither<Failure, NudgeSwitch>(() async {
          final bool yes = choice.getOrElse(() => false);
          return Either<Failure, NudgeSwitch>.right(NudgeSwitch(answeredYes: yes, enabled: yes && await _nudges.areEnabled()));
        }),
      );
}
