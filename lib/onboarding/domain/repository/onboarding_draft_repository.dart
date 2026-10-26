import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/onboarding_draft.dart';

/// Saves and restores the onboarding answers between launches (SPEC FR-ON-6).
abstract interface class OnboardingDraftRepository {
  /// The saved draft.
  ///
  /// Returns [Right] with [Some] draft, [None] when nothing was saved or the saved text is
  /// unreadable (onboarding then starts over), or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Option<OnboardingDraft>> load();

  /// Saves [draft], replacing the previous one.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> save(OnboardingDraft draft);
}
