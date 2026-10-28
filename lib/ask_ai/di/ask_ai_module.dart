import 'package:get_it/get_it.dart';

import '../../core/time/clock.dart';
import '../../core/time/period_calculator.dart';
import '../../ledger/ledger.dart';
import '../data/system_ai_handoff.dart';
import '../domain/ai_handoff.dart';
import '../domain/usecase/get_prompt_input.dart';

/// Registers the Ask AI services; needs the core and ledger services registered first.
void registerAskAiServices(GetIt getIt) => getIt
  ..registerSingleton<AiHandoff>(const SystemAiHandoff())
  ..registerSingleton<GetPromptInput>(
    GetPromptInput(
      ledger: getIt<LedgerRepository>(),
      recurring: getIt<RecurringRepository>(),
      settings: getIt<BudgetSettingsRepository>(),
      categories: getIt<CategoryRepository>(),
      periods: getIt<PeriodCalculator>(),
      clock: getIt<Clock>(),
    ),
  );
