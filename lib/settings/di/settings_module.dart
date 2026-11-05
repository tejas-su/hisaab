import 'package:get_it/get_it.dart';

import '../../core/db/app_database.dart';
import '../../core/notifications/bill_reminders.dart';
import '../../ledger/ledger.dart';
import '../data/datasource/preferences_local_data_source.dart';
import '../data/repository/app_preferences_repository_impl.dart';
import '../domain/repository/app_preferences_repository.dart';
import '../domain/usecase/answer_bill_reminders.dart';
import '../domain/usecase/should_ask_bill_reminders.dart';

/// Registers the app preferences repository and the bill reminders ask; needs the core services
/// registered first, and the ledger's before the ask is first used.
void registerSettingsServices(GetIt getIt) {
  final AppPreferencesRepository preferences =
      AppPreferencesRepositoryImpl(preferences: SqflitePreferencesLocalDataSource(getIt<AppDatabase>()));
  getIt
    ..registerSingleton<AppPreferencesRepository>(preferences)
    // why: lazy, because the ledger registers after settings.
    ..registerLazySingleton<ShouldAskBillReminders>(
      () => ShouldAskBillReminders(preferences: preferences, recurring: getIt<RecurringRepository>()),
    )
    ..registerLazySingleton<AnswerBillReminders>(
      () => AnswerBillReminders(preferences: preferences, reminders: getIt<BillReminders>(), arm: getIt<ArmBillReminders>()),
    );
}
