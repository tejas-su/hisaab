import 'package:get_it/get_it.dart';

import '../../core/time/clock.dart';
import '../../core/time/period_calculator.dart';
import '../../ledger/ledger.dart';
import '../domain/repository/shortcuts_platform.dart';
import '../domain/usecase/project_widget_days.dart';

/// Registers the widget's projection; needs the ledger registered and [platform] made once in `main`.
void registerShortcutsServices(GetIt getIt, {required ShortcutsPlatform platform}) {
  getIt
    ..registerSingleton<ShortcutsPlatform>(platform)
    ..registerSingleton<ProjectWidgetDays>(
      ProjectWidgetDays(
        ledger: getIt<LedgerRepository>(),
        recurring: getIt<RecurringRepository>(),
        settings: getIt<BudgetSettingsRepository>(),
        periods: getIt<PeriodCalculator>(),
        clock: getIt<Clock>(),
      ),
    );
}
