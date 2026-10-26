import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../settings/settings.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/repository/onboarding_draft_repository.dart';
import '../mapper/onboarding_draft_mapper.dart';

/// [OnboardingDraftRepository] stored as JSON through the settings feature's preferences.
final class OnboardingDraftRepositoryImpl implements OnboardingDraftRepository {
  const OnboardingDraftRepositoryImpl({required this._preferences});

  final AppPreferencesRepository _preferences;

  @override
  TaskEither<Failure, Option<OnboardingDraft>> load() => _preferences.onboardingDraft().map(
        (Option<String> json) => json.flatMap(
          (String text) => OnboardingDraftMapper.fromJson(text).match(_discardUnreadable, Option<OnboardingDraft>.of),
        ),
      );

  @override
  TaskEither<Failure, Unit> save(OnboardingDraft draft) =>
      _preferences.saveOnboardingDraft(OnboardingDraftMapper.toJson(draft));

  // why: a draft only saves typing; starting over beats blocking the user on a bad one.
  static Option<OnboardingDraft> _discardUnreadable(Failure failure) {
    AppLogger.log(tag: 'onboarding.draft_unreadable', data: <String, Object?>{'reason': failure.message});
    return const Option<OnboardingDraft>.none();
  }
}
