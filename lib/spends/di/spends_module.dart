import 'package:get_it/get_it.dart';

import '../../core/time/clock.dart';
import '../../core/time/period_calculator.dart';
import '../../ledger/ledger.dart';
import '../domain/usecase/get_month_story.dart';
import '../domain/usecase/get_spends_overview.dart';

/// Registers the Spends use cases; needs the core and ledger services registered first.
void registerSpendsServices(GetIt getIt) => getIt
  ..registerSingleton<GetSpendsOverview>(
      GetSpendsOverview(
        ledger: getIt<LedgerRepository>(),
        recurring: getIt<RecurringRepository>(),
        settings: getIt<BudgetSettingsRepository>(),
        categories: getIt<CategoryRepository>(),
        suggestLimits: getIt<GetSuggestedLimits>(),
        periods: getIt<PeriodCalculator>(),
        clock: getIt<Clock>(),
      ),
    )
  ..registerSingleton<GetMonthStory>(GetMonthStory(overview: getIt<GetSpendsOverview>()));
