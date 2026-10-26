import 'package:expense_tracker/app/app_services.dart';
import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/onboarding/onboarding.dart';
import 'package:expense_tracker/settings/settings.dart';
import 'package:expense_tracker/spends/spends.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';

import '../helpers/test_database.dart';

void main() {
  group('registerAppServices', () {
    test('wires every feature over one real database', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database);
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

    test('wires Spends over the ledger', () async {
      final AppDatabase database = await openTestDatabase();
      final GetIt getIt = GetIt.asNewInstance();
      registerAppServices(getIt, database: database);
      addTearDown(getIt.reset);

      expect(getIt<GetSuggestedLimits>(), isNotNull);
      expect(getIt<ApplySuggestedLimits>(), isNotNull);
      final Either<Failure, SpendsOverview> overview = await getIt<GetSpendsOverview>()(0).run();
      expect(overview.getOrElse((Failure f) => fail(f.message)).isEmpty, isTrue);
    });
  });
}
