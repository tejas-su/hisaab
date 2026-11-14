import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/backup/data/datasource/backup_local_data_source.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/ledger/data/datasource/entries_local_data_source.dart';
import 'package:hisaab/ledger/data/model/entry_model.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_database.dart';

/// A *Not logged* fix and the install line's flag through backup, restore and *Delete everything*
/// (SPEC BR-16, BR-18, FR-FX-1, E91).
void main() {
  late AppDatabase database;
  late SqfliteBackupLocalDataSource source;
  late SqfliteEntriesLocalDataSource entries;

  setUp(() async {
    database = await openTestDatabase();
    source = SqfliteBackupLocalDataSource(database: database, scratch: databaseFactoryFfi);
    entries = SqfliteEntriesLocalDataSource(database);
  });

  Future<int> categoryId(String key) async => (await database.db.query(Tables.categories, where: '${CategoryColumns.key} = ?', whereArgs: <Object?>[key]))
      .single[CategoryColumns.id]! as int;

  Future<int> addFix() async => entries.insert(
        EntryModel(
          amountMinor: 420000,
          currency: 'INR',
          kind: 'out',
          categoryId: await categoryId(CategoryKeys.notLogged),
          date: '2026-10-26',
          note: 'Not logged',
          createdAt: '2026-10-26T10:30:00.000',
        ),
      );

  Future<void> markInstallSeen() => database.db.insert(
        Tables.settings,
        <String, Object?>{SettingsColumns.key: SettingKeys.installLineSeen, SettingsColumns.value: '1'},
      );

  group('backup with a fix', () {
    test('a fix and the hidden rows restore with the flag: the entry still reads as a fix and the line stays used up', () async {
      final int id = await addFix();
      await markInstallSeen();
      final TableRows backup = await source.dump();
      await database.db.delete(Tables.transactions);
      await database.db.delete(Tables.settings, where: '${SettingsColumns.key} = ?', whereArgs: <Object?>[SettingKeys.installLineSeen]);

      await source.replace(backup, const <String, String>{});

      expect((await entries.byId(id))?.categoryKey, CategoryKeys.notLogged);
      expect(await source.dump(), backup);
      expect((await source.dump())[Tables.settings]!.map((Map<String, Object?> r) => r[SettingsColumns.key]), contains(SettingKeys.installLineSeen));
    });

    test('Delete everything removes the fix and the flag, and leaves the hidden rows', () async {
      await addFix();
      await markInstallSeen();

      await source.replace(await source.fresh(), const <String, String>{});

      final TableRows after = await source.dump();
      expect(after[Tables.transactions], isEmpty);
      expect(after[Tables.settings]!.map((Map<String, Object?> r) => r[SettingsColumns.key]), isNot(contains(SettingKeys.installLineSeen)));
      expect(after[Tables.categories]!.map((Map<String, Object?> r) => r[CategoryColumns.key]), containsAll(<String>[CategoryKeys.notLogged, CategoryKeys.notLoggedIn]));
    });

    test('Undo restore brings the replaced data, fix and flag included, back from its snapshot', () async {
      final int id = await addFix();
      await markInstallSeen();
      final TableRows snapshot = await source.dump();
      await source.replace(await source.fresh(), const <String, String>{});
      expect(await entries.byId(id), isNull);

      await source.replace(snapshot, const <String, String>{});

      expect((await entries.byId(id))?.categoryKey, CategoryKeys.notLogged);
      expect(await source.dump(), snapshot);
    });
  });
}
