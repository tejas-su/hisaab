import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/settings/data/datasource/preferences_local_data_source.dart';
import 'package:expense_tracker/settings/data/repository/app_preferences_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late AppPreferencesRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = AppPreferencesRepositoryImpl(preferences: SqflitePreferencesLocalDataSource(database));
  });

  group('AppPreferencesRepositoryImpl', () {
    test('a fresh install has not finished onboarding and has no draft', () async {
      expect(await repository.onboardingDone().run(), Either<Failure, bool>.right(false));
      expect(await repository.onboardingDraft().run(), Either<Failure, Option<String>>.right(const Option<String>.none()));
    });

    test('saves and replaces the draft (FR-ON-6)', () async {
      await repository.saveOnboardingDraft('{"step":"income"}').run();
      await repository.saveOnboardingDraft('{"step":"bills"}').run();
      expect(await repository.onboardingDraft().run(),
          Either<Failure, Option<String>>.right(const Option<String>.of('{"step":"bills"}')));
    });

    test('finishing onboarding sets the flag and clears the draft', () async {
      await repository.saveOnboardingDraft('{"step":"bills"}').run();
      expect(await repository.markOnboardingDone().run(), Either<Failure, Unit>.right(unit));
      expect(await repository.onboardingDone().run(), Either<Failure, bool>.right(true));
      expect(await repository.onboardingDraft().run(), Either<Failure, Option<String>>.right(const Option<String>.none()));
    });

    test('bill reminders were never asked about on a fresh install (spec §6)', () async {
      expect(await repository.billRemindersChoice().run(), Either<Failure, Option<bool>>.right(const Option<bool>.none()));
    });

    test('remembers yes, and then no, to bill reminders', () async {
      expect(await repository.saveBillRemindersChoice(remind: true).run(), Either<Failure, Unit>.right(unit));
      expect(await repository.billRemindersChoice().run(), Either<Failure, Option<bool>>.right(const Option<bool>.of(true)));
      await repository.saveBillRemindersChoice(remind: false).run();
      expect(await repository.billRemindersChoice().run(), Either<Failure, Option<bool>>.right(const Option<bool>.of(false)));
    });

    test('an unreadable stored value becomes InvalidDataFailure', () async {
      await database.db.execute(
        "INSERT INTO ${Tables.settings} (${SettingsColumns.key}, ${SettingsColumns.value}) VALUES (?, X'01')",
        <Object?>[SettingKeys.onboardingDraft],
      );
      expect((await repository.onboardingDraft().run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('database errors become DatabaseFailure', () async {
      await database.close();
      expect((await repository.onboardingDone().run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect((await repository.markOnboardingDone().run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect((await repository.saveOnboardingDraft('{}').run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
