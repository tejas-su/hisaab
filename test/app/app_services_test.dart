import 'package:hisaab/app/app_services.dart';
import 'package:hisaab/ask_ai/ask_ai.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/onboarding/onboarding.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes/fake_bill_reminders.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';

import '../helpers/test_database.dart';

void main() {
  group('registerAppServices', () {
    test('wires every feature over one real database', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database, reminders: FakeBillReminders());
      addTearDown(getIt.reset);

      expect(await getIt<AppPreferencesRepository>().onboardingDone().run(), Either<Failure, bool>.right(false));
      expect((await getIt<CategoryRepository>().all().run()).getOrElse((Failure _) => <Category>[]), hasLength(10));
      expect(getIt<OnboardingDraftRepository>(), isNotNull);
      expect(getIt<CompleteOnboarding>(), isNotNull);
      expect(getIt<SaveEntry>(), isNotNull);
      expect(getIt<DeleteEntry>(), isNotNull);
      expect(getIt<RestoreEntry>(), isNotNull);
      expect(await getIt<PostDueRecurring>()(const NoParams()).run(), Either<Failure, int>.right(0));
      final CycleSummary summary =
          (await getIt<GetCycleSummary>()(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));
      expect(summary.state, const NoIncome());
    });

    test('wires the bill reminders ask over the ledger registered after it (D126)', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database, reminders: FakeBillReminders());
      addTearDown(getIt.reset);

      expect(await getIt<ShouldAskBillReminders>()(const NoParams()).run(), Either<Failure, bool>.right(false));
      expect(await getIt<AnswerBillReminders>()(false).run(), Either<Failure, bool>.right(false));
      expect(getIt<ArmBillReminders>(), isNotNull);
    });

    test('wires Spends over the ledger', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database, reminders: FakeBillReminders());
      addTearDown(getIt.reset);

      expect(getIt<GetSuggestedLimits>(), isNotNull);
      expect(getIt<ApplySuggestedLimits>(), isNotNull);
      final Either<Failure, SpendsOverview> overview = await getIt<GetSpendsOverview>()(0).run();
      expect(overview.getOrElse((Failure f) => fail(f.message)).isEmpty, isTrue);
    });

    test('wires Ask AI over the ledger', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database, reminders: FakeBillReminders());
      addTearDown(getIt.reset);

      const PayCycle october = PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31));
      final Either<Failure, PromptInput> input = await getIt<GetPromptInput>()(october).run();
      expect(input.getOrElse((Failure f) => fail(f.message)).cycles.first, october);
      expect(getIt<AiHandoff>(), isA<AiHandoff>());
    });

    test('wires habits over the ledger (D153)', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database, reminders: FakeBillReminders());
      addTearDown(getIt.reset);

      final Either<Failure, HabitIndex> index = await getIt<GetHabitIndex>()(const NoParams()).run();
      expect(index.getOrElse((Failure f) => fail(f.message)).habits, isEmpty);
      expect(await getIt<SuggestionStateRepository>().all().run(), isA<Right<Failure, Map<int, SuggestionState>>>());
      final Either<Failure, ForgottenUsual> forgotten = await getIt<ForgetUsual>()(1).run();
      expect(await getIt<RestoreUsual>()(forgotten.getOrElse((Failure f) => fail(f.message))).run(), isA<Right<Failure, Unit>>());
      expect((await getIt<SuggestionStateRepository>().all().run()).getOrElse((Failure f) => fail(f.message)), isEmpty);
      expect(getIt<UndoUsualAdd>(), isNotNull);
    });
  });
}
