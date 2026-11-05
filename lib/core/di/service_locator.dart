import 'package:get_it/get_it.dart';

import '../notifications/bill_reminders.dart';

import '../db/app_database.dart';
import '../design/haptics.dart';
import '../money/money_formatter.dart';
import '../time/clock.dart';
import '../time/period_calculator.dart';

/// Registers app-wide services; the composition root, and the only code that fills [GetIt].
///
/// Features register their own repositories and use cases next to this as they land.
void registerCoreServices(GetIt getIt, {required AppDatabase database, required BillReminders reminders}) {
  getIt
    ..registerSingleton<AppDatabase>(database)
    ..registerSingleton<BillReminders>(reminders)
    ..registerSingleton<Clock>(const SystemClock())
    ..registerSingleton<Haptics>(const SystemHaptics())
    ..registerSingleton<MoneyFormatter>(MoneyFormatter())
    ..registerSingleton<PeriodCalculator>(const PeriodCalculator());
}
