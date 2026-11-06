import 'package:get_it/get_it.dart';

import '../../core/db/app_database.dart';
import '../../core/notifications/bill_reminders.dart';
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
import '../domain/usecase/add_own_category.dart';
import '../domain/usecase/apply_suggested_limits.dart';
import '../domain/usecase/arm_bill_reminders.dart';
import '../domain/usecase/change_category_icon.dart';
import '../domain/usecase/delete_bill.dart';
import '../domain/usecase/edit_bill.dart';
import '../domain/usecase/enter_bill_amount.dart';
import '../domain/usecase/skip_bill_occurrence.dart';
import '../domain/usecase/undo_bill_amount.dart';
import '../domain/usecase/unskip_bill_occurrence.dart';
import '../domain/usecase/get_bill_status.dart';
import '../domain/usecase/get_bills.dart';
import '../domain/usecase/get_due_soon_bill.dart';
import '../domain/usecase/get_last_bill_amount.dart';
import '../domain/usecase/get_suggested_limits.dart';
import '../domain/usecase/restore_bill.dart';
import '../domain/usecase/delete_entry.dart';
import '../domain/usecase/get_cycle_summary.dart';
import '../domain/usecase/change_income_amount.dart';
import '../domain/usecase/change_pay_rule.dart';
import '../domain/usecase/correct_latest_pay.dart';
import '../domain/usecase/get_income.dart';
import '../domain/usecase/get_saved_total.dart';
import '../domain/usecase/put_in_extra.dart';
import '../domain/usecase/post_due_recurring.dart';
import '../domain/usecase/rename_category.dart';
import '../domain/usecase/restore_entry.dart';
import '../domain/usecase/save_entry.dart';
import '../domain/usecase/set_category_hidden.dart';

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
    ..registerSingleton<SaveEntry>(SaveEntry(ledger: ledger, recurring: recurring, clock: clock))
    ..registerSingleton<DeleteEntry>(DeleteEntry(ledger: ledger))
    ..registerSingleton<RestoreEntry>(RestoreEntry(ledger: ledger))
    ..registerSingleton<PostDueRecurring>(PostDueRecurring(recurring: recurring, clock: clock))
    ..registerSingleton<GetDueSoonBill>(GetDueSoonBill(recurring: recurring, clock: clock))
    ..registerSingleton<GetLastBillAmount>(GetLastBillAmount(ledger: ledger, clock: clock))
    ..registerSingleton<GetBills>(GetBills(recurring: recurring))
    ..registerSingleton<AddBill>(AddBill(recurring: recurring, categories: getIt<CategoryRepository>(), clock: clock))
    ..registerSingleton<EditBill>(EditBill(recurring: recurring, categories: getIt<CategoryRepository>(), clock: clock))
    ..registerSingleton<EnterBillAmount>(EnterBillAmount(ledger: ledger, recurring: recurring))
    ..registerSingleton<UndoBillAmount>(UndoBillAmount(ledger: ledger, recurring: recurring))
    ..registerSingleton<SkipBillOccurrence>(SkipBillOccurrence(recurring: recurring))
    ..registerSingleton<UnskipBillOccurrence>(UnskipBillOccurrence(recurring: recurring))
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
    ..registerSingleton<ArmBillReminders>(
      ArmBillReminders(recurring: recurring, summary: getIt<GetCycleSummary>(), reminders: getIt<BillReminders>(), clock: clock),
    )
    ..registerSingleton<GetBillStatus>(GetBillStatus(ledger: ledger, clock: clock, summary: getIt<GetCycleSummary>()))
    ..registerSingleton<GetSavedTotal>(GetSavedTotal(ledger: ledger))
    ..registerSingleton<GetIncome>(GetIncome(recurring: recurring, ledger: ledger, clock: clock))
    ..registerSingleton<ChangeIncomeAmount>(ChangeIncomeAmount(recurring: recurring))
    ..registerSingleton<CorrectLatestPay>(CorrectLatestPay(ledger: ledger))
    ..registerSingleton<ChangePayRule>(
      ChangePayRule(recurring: recurring, settings: getIt<BudgetSettingsRepository>(), categories: getIt<CategoryRepository>(), clock: clock),
    )
    ..registerSingleton<PutInExtra>(
      PutInExtra(
        getCycleSummary: getIt<GetCycleSummary>(),
        ledger: ledger,
        categories: getIt<CategoryRepository>(),
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
    ..registerSingleton<ApplySuggestedLimits>(ApplySuggestedLimits(categories: getIt<CategoryRepository>()))
    ..registerSingleton<AddOwnCategory>(AddOwnCategory(categories: getIt<CategoryRepository>()))
    ..registerSingleton<RenameCategory>(RenameCategory(categories: getIt<CategoryRepository>()))
    ..registerSingleton<ChangeCategoryIcon>(ChangeCategoryIcon(categories: getIt<CategoryRepository>()))
    ..registerSingleton<SetCategoryHidden>(SetCategoryHidden(categories: getIt<CategoryRepository>()));
}
