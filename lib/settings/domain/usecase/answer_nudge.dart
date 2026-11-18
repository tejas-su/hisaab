import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/nudges.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/app_preferences_repository.dart';

/// Records the daily nudge answer, from the ask sheet or the Settings switch (SPEC BR-22.8,
/// FR-SE-7). The param is true for *Remind me* or switching on: Android is then asked for the
/// permission, and a refusal is stored as off (E122) so nothing asks again.
///
/// The caller re-arms the nudges afterwards.
final class AnswerNudge implements UseCase<bool, bool> {
  const AnswerNudge({required this._preferences, required this._nudges});

  final AppPreferencesRepository _preferences;
  final Nudges _nudges;

  /// Returns [Right] with true when the nudge is now on, false for *Not now*, switching off or a
  /// refused permission; or [Left] with `DatabaseFailure` when the answer can't be saved.
  @override
  TaskEither<Failure, bool> call(bool params) => (params ? _granted() : TaskEither<Failure, bool>.right(false))
      .flatMap((bool on) => _preferences.saveNudgeChoice(on: on).map((Unit _) => on));

  TaskEither<Failure, bool> _granted() =>
      TaskEither<Failure, bool>(() async => Either<Failure, bool>.right(await _nudges.requestPermission()));
}
