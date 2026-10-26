import 'package:expense_tracker/core/design/haptics.dart';
import 'package:expense_tracker/core/time/clock.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/onboarding/onboarding.dart';
import 'package:expense_tracker/onboarding/data/repository/onboarding_draft_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/repository/budget_settings_repository.dart';
import 'package:expense_tracker/settings/settings.dart';
import 'package:get_it/get_it.dart';

import 'fakes/fake_app_preferences_repository.dart';
import 'fakes/fake_budget_settings_repository.dart';
import 'fakes/fake_category_repository.dart';
import 'fakes/fake_clock.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_ledger_repository.dart';
import 'fakes/fake_recurring_repository.dart';
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
  final FakeClock clock = FakeClock(WorkedExample.now);

  GetCycleSummary get getCycleSummary => GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: clock,
      );

  PostDueRecurring get postDue => PostDueRecurring(recurring: recurring, clock: clock);

  /// A [HomeCubit] over these fakes; the caller loads and closes it.
  HomeCubit homeCubit() => HomeCubit(
        getCycleSummary: getCycleSummary,
        postDueRecurring: postDue,
        getDueSoonBill: GetDueSoonBill(recurring: recurring, clock: clock),
        ledger: ledger,
        recurring: recurring,
        categories: categories,
        deleteEntry: DeleteEntry(ledger: ledger),
        restoreEntry: RestoreEntry(ledger: ledger),
        haptics: haptics,
      );

  /// Registers every service the app's routes look up, backed by these fakes.
  GetIt register(GetIt getIt) => getIt
    ..registerSingleton<Clock>(clock)
    ..registerSingleton<Haptics>(haptics)
    ..registerSingleton<PeriodCalculator>(const PeriodCalculator())
    ..registerSingleton<AppPreferencesRepository>(preferences)
    ..registerSingleton<LedgerRepository>(ledger)
    ..registerSingleton<RecurringRepository>(recurring)
    ..registerSingleton<CategoryRepository>(categories)
    ..registerSingleton<BudgetSettingsRepository>(settings)
    ..registerSingleton<SaveEntry>(SaveEntry(ledger: ledger, clock: clock))
    ..registerSingleton<DeleteEntry>(DeleteEntry(ledger: ledger))
    ..registerSingleton<RestoreEntry>(RestoreEntry(ledger: ledger))
    ..registerSingleton<PostDueRecurring>(postDue)
    ..registerSingleton<GetDueSoonBill>(GetDueSoonBill(recurring: recurring, clock: clock))
    ..registerSingleton<GetBills>(GetBills(recurring: recurring))
    ..registerSingleton<AddBill>(AddBill(recurring: recurring, categories: categories, clock: clock))
    ..registerSingleton<EditBill>(EditBill(recurring: recurring, clock: clock))
    ..registerSingleton<DeleteBill>(DeleteBill(recurring: recurring))
    ..registerSingleton<RestoreBill>(RestoreBill(recurring: recurring))
    ..registerSingleton<GetCycleSummary>(getCycleSummary)
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
  }
}
