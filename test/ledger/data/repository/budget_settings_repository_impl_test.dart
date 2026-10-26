import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/month_start.dart';
import 'package:expense_tracker/ledger/data/datasource/budget_settings_local_data_source.dart';
import 'package:expense_tracker/ledger/data/repository/budget_settings_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/entities/budget_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late BudgetSettingsRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = BudgetSettingsRepositoryImpl(settings: SqfliteBudgetSettingsLocalDataSource(database));
  });

  Future<void> store(String key, String value) => database.db.insert(
        Tables.settings,
        <String, Object?>{SettingsColumns.key: key, SettingsColumns.value: value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  group('BudgetSettingsRepositoryImpl', () {
    test('a fresh install follows payday with nothing kept aside', () async {
      expect(await repository.read().run(), Either<Failure, BudgetSettings>.right(const BudgetSettings()));
    });

    test('reads month start on the 1st and a keep-aside amount', () async {
      await store(SettingKeys.monthStart, MonthStartValues.firstOfMonth);
      await store(SettingKeys.keepAsideMinor, '500000');
      expect(
        await repository.read().run(),
        Either<Failure, BudgetSettings>.right(
          BudgetSettings(monthStart: MonthStart.firstOfMonth, keepAside: Money.fromMajor(5000)),
        ),
      );
    });

    test('defaults a missing month start to payday', () async {
      await database.db.delete(Tables.settings);
      expect((await repository.read().run()).map((BudgetSettings s) => s.monthStart),
          Either<Failure, MonthStart>.right(MonthStart.payday));
    });

    final List<(String, String, String)> bad = <(String, String, String)>[
      ('an unknown month start', SettingKeys.monthStart, 'tuesday'),
      ('a non-numeric keep aside', SettingKeys.keepAsideMinor, 'lots'),
      ('a negative keep aside', SettingKeys.keepAsideMinor, '-100'),
    ];
    for (final (String name, String key, String value) in bad) {
      test('returns InvalidDataFailure for $name', () async {
        await store(key, value);
        expect((await repository.read().run()).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }

    test('returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.read().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
