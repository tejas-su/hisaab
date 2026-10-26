import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../../../settings/settings.dart';
import '../entities/onboarding_draft.dart';
import '../entities/setup_labels.dart';
import '../ledger_setup_builder.dart';

/// The finished answers and the names to store on the rules they create.
final class CompleteOnboardingParams extends Equatable {
  const CompleteOnboardingParams({required this.draft, required this.labels});

  final OnboardingDraft draft;
  final SetupLabels labels;

  @override
  List<Object?> get props => <Object?>[draft, labels];
}

/// Finishes onboarding (SPEC FR-ON-5): writes the ledger's starting rules, marks onboarding done,
/// then runs the recurring engine so this cycle's salary and bills appear at once.
///
/// Each step is safe to repeat: setup replaces rules wholesale and the engine is idempotent, so
/// retrying after any failure never duplicates anything.
final class CompleteOnboarding implements UseCase<Unit, CompleteOnboardingParams> {
  const CompleteOnboarding({
    required this._categories,
    required this._recurring,
    required this._preferences,
    required this._postDue,
    required this._clock,
  });

  final CategoryRepository _categories;
  final RecurringRepository _recurring;
  final AppPreferencesRepository _preferences;
  final PostDueRecurring _postDue;
  final Clock _clock;

  /// Returns [Right] with [unit] once onboarding is marked done, or [Left] with
  /// `InvalidDataFailure` for incomplete answers or `DatabaseFailure` if a write fails.
  @override
  TaskEither<Failure, Unit> call(CompleteOnboardingParams params) => _categories
      .all()
      .chainEither(
        (List<Category> categories) => LedgerSetupBuilder.build(
          params.draft,
          today: _clock.today(),
          categories: categories,
          labels: params.labels,
        ),
      )
      .flatMap(_recurring.startFresh)
      .flatMap((Unit _) => _preferences.markOnboardingDone())
      .flatMap((Unit _) => _postDueIgnoringFailure());

  // why: onboarding is already done at this point; Home runs the engine again on its first
  // load, so a failure here only delays the posts and must not trap the user in onboarding.
  TaskEither<Failure, Unit> _postDueIgnoringFailure() => _postDue(const NoParams())
      .map((int _) => unit)
      .orElse((Failure failure) {
        AppLogger.log(tag: 'onboarding.post_due_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        return TaskEither<Failure, Unit>.right(unit);
      });
}
