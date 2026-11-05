import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/theme_choice.dart';

/// App preferences owned by the settings feature: onboarding progress (DECISIONS D20), the
/// answer to "Remind you on the day it's due?" (D126) and the look (FR-SE-3).
abstract interface class AppPreferencesRepository {
  /// Whether onboarding was finished (SPEC FR-ON-1).
  ///
  /// Returns [Right] with the flag (false on a fresh install), or [Left] with `DatabaseFailure`.
  TaskEither<Failure, bool> onboardingDone();

  /// Marks onboarding finished and deletes the saved draft, in one transaction.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> markOnboardingDone();

  /// The saved onboarding draft as JSON text, for resuming (SPEC FR-ON-6).
  ///
  /// Returns [Right] with [Some] text or [None] when no draft exists, or [Left] with
  /// `DatabaseFailure`.
  TaskEither<Failure, Option<String>> onboardingDraft();

  /// Saves the onboarding draft [json], replacing any earlier one.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> saveOnboardingDraft(String json);

  /// The answer to "Remind you on the day it's due?" (spec §6).
  ///
  /// Returns [Right] with [Some] true for *Remind me*, [Some] false for *Not now*, or [None]
  /// when it was never asked; or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Option<bool>> billRemindersChoice();

  /// Remembers the answer, [remind] or not; it is never asked again.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> saveBillRemindersChoice({required bool remind});

  /// The look the user picked (SPEC FR-SE-3).
  ///
  /// Returns [Right] with the choice, [ThemeChoice.matchPhone] when none was picked or the stored
  /// value is unknown; or [Left] with `DatabaseFailure`.
  TaskEither<Failure, ThemeChoice> themeChoice();

  /// Remembers [choice] as the look.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> saveThemeChoice(ThemeChoice choice);
}
