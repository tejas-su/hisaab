import 'package:get_it/get_it.dart';

import '../../core/time/clock.dart';
import '../../core/time/period_calculator.dart';
import '../../ledger/ledger.dart';
import '../domain/usecase/get_afford_inputs.dart';
import '../domain/usecase/get_month_story.dart';
import '../domain/usecase/get_spends_overview.dart';
import '../domain/usecase/is_income_set_up.dart';
import '../domain/usecase/start_saving_for.dart';
import '../domain/usecase/undo_start_saving.dart';

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
  ..registerSingleton<IsIncomeSetUp>(
    IsIncomeSetUp(
      getIncome: getIt<GetIncome>(),
      ledger: getIt<LedgerRepository>(),
    ),
  )
  ..registerSingleton<GetMonthStory>(
    GetMonthStory(overview: getIt<GetSpendsOverview>()),
  )
  ..registerSingleton<GetAffordInputs>(
    GetAffordInputs(
      ledger: getIt<LedgerRepository>(),
      recurring: getIt<RecurringRepository>(),
      settings: getIt<BudgetSettingsRepository>(),
      periods: getIt<PeriodCalculator>(),
      clock: getIt<Clock>(),
    ),
  )
  ..registerSingleton<StartSavingFor>(
    StartSavingFor(
      addBill: getIt<AddBill>(),
      editBill: getIt<EditBill>(),
      recurring: getIt<RecurringRepository>(),
    ),
  )
  ..registerSingleton<UndoStartSaving>(
    UndoStartSaving(recurring: getIt<RecurringRepository>()),
  );
