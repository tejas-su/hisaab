import 'package:hisaab/backup/data/datasource/backup_local_data_source.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/db/migrations/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fixtures/backup/backup_rows.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late SqfliteBackupLocalDataSource source;

  setUp(() async {
    database = await openTestDatabase();
    source = SqfliteBackupLocalDataSource(database: database, scratch: databaseFactoryFfi);
    await seedMoney(database.db);
  });

  group('SqfliteBackupLocalDataSource', () {
    group('dump', () {
      test('holds every table, including notes, inactive rules and created_at (NFR-5)', () async {
        final TableRows rows = await source.dump();

        expect(rows.keys, containsAll(<String>[Tables.categories, Tables.recurring, Tables.transactions, Tables.settings, Tables.recurringSkips]));
        expect(rows[Tables.recurring]!.map((Map<String, Object?> r) => r[RecurringColumns.active]), <int>[1, 0]);
        expect(rows[Tables.transactions]!.single[TransactionColumns.note], 'chai ☕ with Ravi');
        expect(rows[Tables.transactions]!.single[TransactionColumns.createdAt], '2026-11-05T09:30:00.000');
      });

      test('leaves out the settings that stay on this phone', () async {
        await source.writeSetting(SettingKeys.lastBackup, '2026-11-01');
        await source.writeSetting(SettingKeys.restoreSnapshot, '{}');
        await source.writeSetting(SettingKeys.restoredAt, '2026-11-01T10:00:00.000');

        final TableRows rows = await source.dump();

        expect(rows[Tables.settings]!.map((Map<String, Object?> r) => r[SettingsColumns.key]), isNot(contains(SettingKeys.lastBackup)));
        expect(rows[Tables.settings]!.map((Map<String, Object?> r) => r[SettingsColumns.key]), contains(SettingKeys.onboardingDone));
        expect(rows[Tables.settings]!.length, 3);
      });
    });

    group('replace', () {
      test('round-trips the data exactly (NFR-5)', () async {
        final TableRows before = await source.dump();
        await database.db.delete(Tables.transactions);

        await source.replace(before, const <String, String>{});

        expect(await source.dump(), before);
      });

      test('writes the local settings alongside', () async {
        await source.replace(await source.dump(), const <String, String>{SettingKeys.lastBackup: '2026-11-06'});

        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.of('2026-11-06'));
      });

      test('a row that breaks a foreign key changes nothing (E38)', () async {
        final TableRows before = await source.dump();
        final TableRows broken = <String, List<Map<String, Object?>>>{
          ...before,
          Tables.transactions: <Map<String, Object?>>[
            <String, Object?>{...before[Tables.transactions]!.single, TransactionColumns.categoryId: 999},
          ],
        };

        await expectLater(source.replace(broken, const <String, String>{}), throwsA(anything));

        expect(await source.dump(), before);
      });

      test('a table the app does not have changes nothing', () async {
        final TableRows before = await source.dump();

        await expectLater(
          source.replace(<String, List<Map<String, Object?>>>{
            ...before,
            'mystery': <Map<String, Object?>>[
              <String, Object?>{'id': 1},
            ],
          }, const <String, String>{}),
          throwsA(anything),
        );

        expect(await source.dump(), before);
      });
    });

    test('fresh is what a new install holds', () async {
      final AppDatabase another = await openTestDatabase();

      final TableRows fresh = await source.fresh();

      expect(fresh, await SqfliteBackupLocalDataSource(database: another, scratch: databaseFactoryFfi).dump());
      expect(fresh[Tables.transactions], isEmpty);
      expect(fresh[Tables.categories], isNotEmpty);
    });

    group('upgrade', () {
      test('brings v1 rows up to the current schema', () async {
        final Database v1 = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false, version: 1, onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 1)),
        );
        addTearDown(v1.close);
        await seedMoney(v1);
        final TableRows old = await SqfliteBackupLocalDataSource(database: database, scratch: databaseFactoryFfi).dumpOf(v1);

        final TableRows upgraded = await source.upgrade(1, old);

        expect(upgraded.keys, contains(Tables.recurringSkips));
        expect(upgraded[Tables.recurring]!.first[RecurringColumns.amountMode], AmountModeValues.fixed);
        expect(upgraded[Tables.transactions]!.single[TransactionColumns.note], 'chai ☕ with Ravi');
      });

      test('current rows come back unchanged', () async {
        final TableRows rows = await source.dump();

        expect(await source.upgrade(AppDatabase.schemaVersion, rows), rows);
      });

      test('a column the schema does not have throws', () async {
        final TableRows rows = await source.dump();

        await expectLater(
          source.upgrade(AppDatabase.schemaVersion, <String, List<Map<String, Object?>>>{
            ...rows,
            Tables.settings: <Map<String, Object?>>[
              <String, Object?>{'key': 'x', 'colour': 'red'},
            ],
          }),
          throwsA(anything),
        );
      });
    });

    group('suggestion_state (BR-16, BR-17)', () {
      const Map<String, Object?> quiet = <String, Object?>{
        SuggestionStateColumns.categoryId: 1,
        SuggestionStateColumns.quietOn: '2026-11-05',
        SuggestionStateColumns.restUntil: '2026-12-05',
        SuggestionStateColumns.forgottenAt: '2026-11-05T09:30:00.000',
      };

      test('dump carries suggestion_state', () async {
        await database.db.insert(Tables.suggestionState, quiet);

        expect((await source.dump())[Tables.suggestionState], <Map<String, Object?>>[quiet]);
      });

      test('a v3 backup upgrades to an empty suggestion_state', () async {
        final Database v3 = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false, version: 3, onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 3)),
        );
        addTearDown(v3.close);
        await seedMoney(v3);
        final TableRows old = await source.dumpOf(v3);
        expect(old.keys, isNot(contains(Tables.suggestionState)));

        final TableRows upgraded = await source.upgrade(3, old);

        expect(upgraded[Tables.suggestionState], isEmpty);
        expect(upgraded[Tables.transactions]!.single[TransactionColumns.note], 'chai ☕ with Ravi');
      });

      test('fresh has no suggestion_state rows', () async {
        expect((await source.fresh())[Tables.suggestionState], isEmpty);
      });

      for (final bool stateFirst in <bool>[true, false]) {
        test('replace puts suggestion_state rows back when its table comes ${stateFirst ? 'first' : 'last'} in the file', () async {
          await database.db.insert(Tables.suggestionState, quiet);
          final TableRows before = await source.dump();
          final TableRows others = <String, List<Map<String, Object?>>>{...before}..remove(Tables.suggestionState);
          final TableRows state = <String, List<Map<String, Object?>>>{Tables.suggestionState: before[Tables.suggestionState]!};
          await database.db.delete(Tables.suggestionState);

          await source.replace(
            stateFirst ? <String, List<Map<String, Object?>>>{...state, ...others} : <String, List<Map<String, Object?>>>{...others, ...state},
            const <String, String>{},
          );

          expect((await source.dump())[Tables.suggestionState], <Map<String, Object?>>[quiet]);
          expect(await source.dump(), before);
        });
      }
    });

    group('settings and counts', () {
      test('reads, writes and removes settings', () async {
        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.none());

        await source.writeSetting(SettingKeys.lastBackup, '2026-11-05');
        await source.writeSetting(SettingKeys.lastBackup, '2026-11-06');
        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.of('2026-11-06'));

        await source.removeSettings(<String>{SettingKeys.lastBackup});
        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.none());
      });

      test('counts entries, and those created after an instant (E42)', () async {
        expect(await source.entryCount(), 1);
        expect(await source.entriesCreatedAfter('2026-11-05T09:00:00.000'), 1);
        expect(await source.entriesCreatedAfter('2026-11-05T09:30:00.000'), 0);
      });
    });
  });
}

extension on SqfliteBackupLocalDataSource {
  /// Dumps any database the same way, for building old-version fixtures.
  Future<TableRows> dumpOf(Database db) async {
    final List<Map<String, Object?>> names = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final List<String> tables = names.map((Map<String, Object?> r) => r['name']).whereType<String>().toList();
    return <String, List<Map<String, Object?>>>{
      for (final String table in tables) table: await db.query(table, orderBy: 'rowid'),
    };
  }
}
