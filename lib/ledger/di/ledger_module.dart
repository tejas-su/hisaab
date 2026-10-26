import 'package:get_it/get_it.dart';

import '../../core/db/app_database.dart';
import '../../core/time/clock.dart';
import '../../core/time/period_calculator.dart';
import '../data/datasource/budget_settings_local_data_source.dart';
import '../data/datasource/categories_local_data_source.dart';
import '../data/datasource/entries_local_data_source.dart';
import '../data/datasource/recurring_local_data_source.dart';
import '../data/repository/budget_settings_repository_impl.dart';
import '../data/repository/category_repository_impl.dart';
import '../data/repository/ledger_repository_impl.dart';
import '../data/repository/recurring_repository_impl.dart';
import '../domain/repository/budget_settings_repository.dart';
import '../domain/repository/category_repository.dart';
import '../domain/repository/ledger_repository.dart';
import '../domain/repository/recurring_repository.dart';
import '../domain/usecase/add_bill.dart';
import '../domain/usecase/apply_suggested_limits.dart';
import '../domain/usecase/delete_bill.dart';
import '../domain/usecase/edit_bill.dart';
import '../domain/usecase/get_bills.dart';
import '../domain/usecase/get_due_soon_bill.dart';
import '../domain/usecase/get_suggested_limits.dart';
import '../domain/usecase/restore_bill.dart';
import '../domain/usecase/delete_entry.dart';
import '../domain/usecase/get_cycle_summary.dart';
import '../domain/usecase/post_due_recurring.dart';
import '../domain/usecase/restore_entry.dart';
import '../domain/usecase/save_entry.dart';

/// Registers the ledger's repositories and use cases; needs the core services registered first.
void registerLedgerServices(GetIt getIt) {
  final AppDatabase database = getIt<AppDatabase>();
  final Clock clock = getIt<Clock>();
  final LedgerRepositoryImpl ledger = LedgerRepositoryImpl(entries: SqfliteEntriesLocalDataSource(database), clock: clock);
  final RecurringRepositoryImpl recurring =
      RecurringRepositoryImpl(recurring: SqfliteRecurringLocalDataSource(database), clock: clock);
  getIt
    ..registerSingleton<LedgerRepository>(ledger, dispose: (LedgerRepository _) => ledger.dispose())
    ..registerSingleton<RecurringRepository>(recurring, dispose: (RecurringRepository _) => recurring.dispose())
    ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(categories: SqfliteCategoriesLocalDataSource(database)))
    ..registerSingleton<BudgetSettingsRepository>(
      BudgetSettingsRepositoryImpl(settings: SqfliteBudgetSettingsLocalDataSource(database)),
    )
    ..registerSingleton<SaveEntry>(SaveEntry(ledger: ledger, clock: clock))
    ..registerSingleton<DeleteEntry>(DeleteEntry(ledger: ledger))
    ..registerSingleton<RestoreEntry>(RestoreEntry(ledger: ledger))
    ..registerSingleton<PostDueRecurring>(PostDueRecurring(recurring: recurring, clock: clock))
    ..registerSingleton<GetDueSoonBill>(GetDueSoonBill(recurring: recurring, clock: clock))
    ..registerSingleton<GetBills>(GetBills(recurring: recurring))
    ..registerSingleton<AddBill>(AddBill(recurring: recurring, categories: getIt<CategoryRepository>(), clock: clock))
    ..registerSingleton<EditBill>(EditBill(recurring: recurring, clock: clock))
    ..registerSingleton<DeleteBill>(DeleteBill(recurring: recurring))
    ..registerSingleton<RestoreBill>(RestoreBill(recurring: recurring))
    ..registerSingleton<GetCycleSummary>(
      GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: getIt<BudgetSettingsRepository>(),
        periods: getIt<PeriodCalculator>(),
        clock: clock,
      ),
    )
    ..registerSingleton<GetSuggestedLimits>(
      GetSuggestedLimits(
        ledger: ledger,
        recurring: recurring,
        settings: getIt<BudgetSettingsRepository>(),
        categories: getIt<CategoryRepository>(),
        periods: getIt<PeriodCalculator>(),
        clock: clock,
      ),
    )
    ..registerSingleton<ApplySuggestedLimits>(ApplySuggestedLimits(categories: getIt<CategoryRepository>()));
}
