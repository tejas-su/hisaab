import 'package:get_it/get_it.dart';

import '../ask_ai/ask_ai.dart';
import '../backup/backup.dart';
import '../core/db/app_database.dart';
import '../core/di/service_locator.dart';
import '../core/notifications/bill_reminders.dart';
import '../ledger/ledger.dart';
import '../onboarding/onboarding.dart';
import '../settings/settings.dart';
import '../spends/spends.dart';

/// Registers every service the app needs, core first and then each feature in dependency order.
void registerAppServices(GetIt getIt, {required AppDatabase database, required BillReminders reminders}) {
  registerCoreServices(getIt, database: database, reminders: reminders);
  registerSettingsServices(getIt);
  registerLedgerServices(getIt);
  registerOnboardingServices(getIt);
  registerSpendsServices(getIt);
  registerAskAiServices(getIt);
  registerBackupServices(getIt);
}
