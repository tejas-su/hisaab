import 'package:expense_tracker/ask_ai/ask_ai.dart';
import 'package:expense_tracker/backup/backup.dart';
import 'package:expense_tracker/core/design/haptics.dart';
import 'package:expense_tracker/core/notifications/bill_reminders.dart';
import 'package:expense_tracker/core/time/clock.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/spends.dart';
import 'package:expense_tracker/onboarding/onboarding.dart';
import 'package:expense_tracker/onboarding/data/repository/onboarding_draft_repository_impl.dart';
import 'package:expense_tracker/settings/settings.dart';
import 'package:get_it/get_it.dart';

import 'fakes/fake_backup_repository.dart';
import 'fakes/fake_ai_handoff.dart';
import 'fakes/fake_app_preferences_repository.dart';
import 'fakes/fake_bill_reminders.dart';
import 'fakes/fake_budget_settings_repository.dart';
import 'fakes/fake_category_repository.dart';
import 'fakes/fake_clock.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_ledger_repository.dart';
import 'fakes/fake_recurring_repository.dart';
import 'fixtures/ask_ai/prompt_input.dart';
import 'fixtures/ledger/worked_example.dart';

/// In-memory stand-ins for every service, seeded with the SPEC worked example by default.
final class FakeServices {
  FakeServices({bool onboardingDone = true, List<Entry>? entries, List<RecurringRule>? rules})
      : preferences = FakeAppPreferencesRepository(done: onboardingDone),
        ledger = FakeLedgerRepository(entries ?? WorkedExample.entries),
        recurring = FakeRecurringRepository(rules ?? WorkedExample.rules);

  final FakeAppPreferencesRepository preferences;
  final FakeLedgerRepository ledger;
  final FakeRecurringRepository recurring;
  final FakeCategoryRepository categories = FakeCategoryRepository();
  final FakeBudgetSettingsRepository settings = FakeBudgetSettingsRepository();
  final FakeHaptics haptics = FakeHaptics();
  final FakeAiHandoff handoff = FakeAiHandoff();
  final FakeBillReminders reminders = FakeBillReminders();
  final FakeClock clock = FakeClock(WorkedExample.now);
  final FakeBackupRepository backups = FakeBackupRepository();

  GetCycleSummary get getCycleSummary => GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: clock,
      );

  /// Arms the reminders over these fakes.
  ArmBillReminders get armBillReminders =>
      ArmBillReminders(recurring: recurring, summary: getCycleSummary, reminders: reminders, clock: clock);

  PostDueRecurring get postDue => PostDueRecurring(recurring: recurring, clock: clock);

  /// A [HomeBloc] over these fakes; the caller loads and closes it.
  HomeBloc homeBloc() => HomeBloc(
        getCycleSummary: getCycleSummary,
        postDueRecurring: postDue,
        getDueSoonBill: GetDueSoonBill(recurring: recurring, clock: clock),
        ledger: ledger,
        recurring: recurring,
        categories: categories,
        deleteEntry: DeleteEntry(ledger: ledger),
        restoreEntry: RestoreEntry(ledger: ledger),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        undoBillAmount: UndoBillAmount(ledger: ledger, recurring: recurring),
        unskipBill: UnskipBillOccurrence(recurring: recurring),
        haptics: haptics,
      );

  /// The limit offer's use case over these fakes.
  GetSuggestedLimits get getSuggestedLimits => GetSuggestedLimits(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        categories: categories,
        periods: const PeriodCalculator(),
        clock: clock,
      );

  /// The Spends overview over these fakes.
  GetSpendsOverview get getSpendsOverview => GetSpendsOverview(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        categories: categories,
        suggestLimits: getSuggestedLimits,
        periods: const PeriodCalculator(),
        clock: clock,
      );

  /// A [SpendsBloc] over these fakes; the caller loads and closes it.
  /// An [AskAiBloc] for the worked example's cycle over these fakes; the caller loads and closes it.
  AskAiBloc askAiBloc() => AskAiBloc(
        cycle: workedCycles.first,
        getInput: GetPromptInput(
          ledger: ledger,
          recurring: recurring,
          settings: settings,
          categories: categories,
          periods: const PeriodCalculator(),
          clock: clock,
        ),
        handoff: handoff,
        haptics: haptics,
        nameOf: englishName,
      );

  SpendsBloc spendsBloc() => SpendsBloc(
        getOverview: getSpendsOverview,
        applyLimits: ApplySuggestedLimits(categories: categories),
        ledger: ledger,
        haptics: haptics,
      );

  /// Registers every service the app's routes look up, backed by these fakes.
  GetIt register(GetIt getIt) => getIt
    ..registerSingleton<Clock>(clock)
    ..registerSingleton<Haptics>(haptics)
    ..registerSingleton<PeriodCalculator>(const PeriodCalculator())
    ..registerSingleton<AppPreferencesRepository>(preferences)
    ..registerSingleton<BillReminders>(reminders)
    ..registerSingleton<LedgerRepository>(ledger)
    ..registerSingleton<RecurringRepository>(recurring)
    ..registerSingleton<CategoryRepository>(categories)
    ..registerSingleton<BudgetSettingsRepository>(settings)
    ..registerSingleton<SaveEntry>(SaveEntry(ledger: ledger, recurring: recurring, clock: clock))
    ..registerSingleton<DeleteEntry>(DeleteEntry(ledger: ledger))
    ..registerSingleton<RestoreEntry>(RestoreEntry(ledger: ledger))
    ..registerSingleton<PostDueRecurring>(postDue)
    ..registerSingleton<GetDueSoonBill>(GetDueSoonBill(recurring: recurring, clock: clock))
    ..registerSingleton<GetLastBillAmount>(GetLastBillAmount(ledger: ledger, clock: clock))
    ..registerSingleton<GetBillStatus>(GetBillStatus(ledger: ledger, clock: clock, summary: getCycleSummary))
    ..registerSingleton<GetBills>(GetBills(recurring: recurring))
    ..registerSingleton<AddBill>(AddBill(recurring: recurring, categories: categories, clock: clock))
    ..registerSingleton<EditBill>(EditBill(recurring: recurring, categories: categories, clock: clock))
    ..registerSingleton<EnterBillAmount>(EnterBillAmount(ledger: ledger, recurring: recurring))
    ..registerSingleton<UndoBillAmount>(UndoBillAmount(ledger: ledger, recurring: recurring))
    ..registerSingleton<SkipBillOccurrence>(SkipBillOccurrence(recurring: recurring))
    ..registerSingleton<UnskipBillOccurrence>(UnskipBillOccurrence(recurring: recurring))
    ..registerSingleton<DeleteBill>(DeleteBill(recurring: recurring))
    ..registerSingleton<RestoreBill>(RestoreBill(recurring: recurring))
    ..registerSingleton<GetCycleSummary>(getCycleSummary)
    ..registerSingleton<ArmBillReminders>(armBillReminders)
    ..registerSingleton<ShouldAskBillReminders>(ShouldAskBillReminders(preferences: preferences, recurring: recurring))
    ..registerSingleton<AnswerBillReminders>(AnswerBillReminders(preferences: preferences, reminders: reminders, arm: armBillReminders))
    ..registerSingleton<GetSavedTotal>(GetSavedTotal(ledger: ledger))
    ..registerSingleton<GetIncome>(GetIncome(recurring: recurring, ledger: ledger, clock: clock))
    ..registerSingleton<ChangeIncomeAmount>(ChangeIncomeAmount(recurring: recurring))
    ..registerSingleton<CorrectLatestPay>(CorrectLatestPay(ledger: ledger))
    ..registerSingleton<ChangePayRule>(ChangePayRule(recurring: recurring, settings: settings, categories: categories, clock: clock))
    ..registerSingleton<PutInExtra>(
      PutInExtra(getCycleSummary: getCycleSummary, ledger: ledger, categories: categories, clock: clock),
    )
    ..registerSingleton<GetSuggestedLimits>(getSuggestedLimits)
    ..registerSingleton<ApplySuggestedLimits>(ApplySuggestedLimits(categories: categories))
    ..registerSingleton<AddOwnCategory>(AddOwnCategory(categories: categories))
    ..registerSingleton<RenameCategory>(RenameCategory(categories: categories))
    ..registerSingleton<ChangeCategoryIcon>(ChangeCategoryIcon(categories: categories))
    ..registerSingleton<SetCategoryHidden>(SetCategoryHidden(categories: categories))
    ..registerSingleton<GetSpendsOverview>(getSpendsOverview)
    ..registerSingleton<GetPromptInput>(
      GetPromptInput(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        categories: categories,
        periods: const PeriodCalculator(),
        clock: clock,
      ),
    )
    ..registerSingleton<AiHandoff>(handoff)
    ..registerSingleton<BackupRepository>(backups)
    ..registerSingleton<DeleteEverything>(DeleteEverything(backups: backups, reminders: reminders))
    ..registerSingleton<OnboardingDraftRepository>(OnboardingDraftRepositoryImpl(preferences: preferences))
    ..registerSingleton<CompleteOnboarding>(
      CompleteOnboarding(
        categories: categories,
        recurring: recurring,
        preferences: preferences,
        postDue: postDue,
        clock: clock,
      ),
    );

  /// Closes the fakes' change streams.
  Future<void> dispose() async {
    await ledger.dispose();
    await recurring.dispose();
    await reminders.dispose();
  }
}
