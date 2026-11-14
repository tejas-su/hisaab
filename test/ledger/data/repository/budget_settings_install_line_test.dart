import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/data/datasource/budget_settings_local_data_source.dart';
import 'package:hisaab/ledger/data/repository/budget_settings_repository_impl.dart';

import '../../../helpers/test_database.dart';

/// The install line's *seen* flag, one `settings` row that backup carries (FR-HO-3, BR-16, C11).
void main() {
  late AppDatabase database;
  late BudgetSettingsRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = BudgetSettingsRepositoryImpl(settings: SqfliteBudgetSettingsLocalDataSource(database));
  });

  group('BudgetSettingsRepositoryImpl install line flag', () {
    test('is not seen on a fresh install', () async {
      expect(await repository.installLineSeen().run(), const Right<Failure, bool>(false));
    });

    test('marking it seen stores install_line_seen = 1 and reads back true', () async {
      await repository.markInstallLineSeen().run();

      expect(await repository.installLineSeen().run(), const Right<Failure, bool>(true));
      final List<Map<String, Object?>> rows =
          await database.db.query(Tables.settings, where: '${SettingsColumns.key} = ?', whereArgs: <Object?>[SettingKeys.installLineSeen]);
      expect(rows.single[SettingsColumns.value], '1');
    });

    test('marking twice is harmless', () async {
      await repository.markInstallLineSeen().run();

      expect((await repository.markInstallLineSeen().run()).isRight(), isTrue);
    });

    test('a closed database is a DatabaseFailure on both calls', () async {
      await database.close();

      expect((await repository.installLineSeen().run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect((await repository.markInstallLineSeen().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
