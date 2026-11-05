import 'package:expense_tracker/app/app_shell.dart';
import 'package:expense_tracker/app/hisaab_app.dart';
import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/design/haptics.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money_formatter.dart';
import 'package:expense_tracker/core/time/clock.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes/fake_bill_reminders.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_services.dart';

void main() {
  group('HisaabApp', () {
    testWidgets('boots into the adaptive shell', (WidgetTester tester) async {
      final FakeServices services = FakeServices();
      addTearDown(services.dispose);
      await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('shows a recovery message when the database failed to open', (WidgetTester tester) async {
      await tester.pumpWidget(const HisaabApp.startupFailed());
      await tester.pumpAndSettle();
      expect(find.textContaining("couldn't open its data"), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });
  });

  group('registerCoreServices', () {
    test('registers every core service once', () async {
      sqfliteFfiInit();
      final Either<Failure, AppDatabase> opened =
          await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath, singleInstance: false).run();
      final AppDatabase database = opened.getOrElse((Failure failure) => fail(failure.message));
      addTearDown(database.close);

      final GetIt getIt = GetIt.asNewInstance();
      registerCoreServices(getIt, database: database, reminders: FakeBillReminders());

      expect(getIt<AppDatabase>(), same(database));
      expect(getIt<Clock>(), isA<SystemClock>());
      expect(getIt<Haptics>(), isA<SystemHaptics>());
      expect(getIt<MoneyFormatter>().locale, 'en_IN');
      expect(getIt<PeriodCalculator>(), isA<PeriodCalculator>());
    });
  });
}
