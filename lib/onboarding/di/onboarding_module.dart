import 'package:get_it/get_it.dart';

import '../../core/time/clock.dart';
import '../../ledger/ledger.dart';
import '../../settings/settings.dart';
import '../data/repository/onboarding_draft_repository_impl.dart';
import '../domain/repository/onboarding_draft_repository.dart';
import '../domain/usecase/complete_onboarding.dart';

/// Registers onboarding's draft repository and use case; needs ledger and settings first.
void registerOnboardingServices(GetIt getIt) => getIt
  ..registerSingleton<OnboardingDraftRepository>(
    OnboardingDraftRepositoryImpl(preferences: getIt<AppPreferencesRepository>()),
  )
  ..registerSingleton<CompleteOnboarding>(
    CompleteOnboarding(
      categories: getIt<CategoryRepository>(),
      recurring: getIt<RecurringRepository>(),
      preferences: getIt<AppPreferencesRepository>(),
      postDue: getIt<PostDueRecurring>(),
      clock: getIt<Clock>(),
    ),
  );
