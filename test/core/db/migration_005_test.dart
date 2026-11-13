import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/backup/data/datasource/backup_local_data_source.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/db/migrations/migrations.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fixtures/backup/backup_rows.dart';
import '../../helpers/test_database.dart';

void main() {
  sqfliteFfiInit();

  Future<String> versionFile(int version, Future<void> Function(Database db) fill) async {
    final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_v$version');
    addTearDown(() => dir.delete(recursive: true));
    final String path = p.join(dir.path, AppDatabase.fileName);
    final Database old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (Database db, int _) => runMigrations(db, from: 0, to: version),
      ),
    );
    await fill(old);
    await old.close();
    return path;
  }

  Future<AppDatabase> reopen(String path) async {
    final Either<Failure, AppDatabase> opened =
        await AppDatabase.open(factory: databaseFactoryFfi, path: path, singleInstance: false).run();
    final AppDatabase database = opened.getOrElse((Failure failure) => fail(failure.message));
    addTearDown(database.close);
    return database;
  }

  Future<void> rentAndEntries(Database db) async {
    await db.insert(Tables.recurring, <String, Object?>{
      RecurringColumns.id: 2,
      RecurringColumns.label: 'Rent',
      RecurringColumns.amountMinor: 820000,
      RecurringColumns.kind: EntryKindValues.spent,
      RecurringColumns.categoryId: 7,
      RecurringColumns.frequency: FrequencyValues.monthly,
      RecurringColumns.anchorDate: '2026-10-05',
      RecurringColumns.nextDue: '2026-11-05',
    });
    await db.insert(Tables.transactions, <String, Object?>{
      TransactionColumns.id: 2,
      TransactionColumns.amountMinor: 820000,
      TransactionColumns.kind: EntryKindValues.spent,
      TransactionColumns.categoryId: 7,
      TransactionColumns.date: '2026-10-05',
      TransactionColumns.recurringId: 2,
      TransactionColumns.createdAt: '2026-10-05T00:01:00.000',
    });
    await db.insert(Tables.transactions, <String, Object?>{
      TransactionColumns.id: 3,
      TransactionColumns.amountMinor: 2000,
      TransactionColumns.kind: EntryKindValues.spent,
      TransactionColumns.categoryId: 1,
      TransactionColumns.date: '2026-10-26',
      TransactionColumns.note: 'Chai',
      TransactionColumns.createdAt: '2026-10-26T10:05:00.000',
    });
  }

  Future<List<String>> indexNames(Database db) async => (await db.rawQuery('PRAGMA index_list(${Tables.transactions})'))
      .map((Map<String, Object?> row) => row['name']! as String)
      .toList();

  Map<String, Object?> entryRow({
    String date = '2026-10-26',
    int? recurringId,
    int? savingId,
    String kind = EntryKindValues.used,
  }) =>
      <String, Object?>{
        TransactionColumns.amountMinor: 400000,
        TransactionColumns.kind: kind,
        TransactionColumns.categoryId: 11,
        TransactionColumns.date: date,
        TransactionColumns.recurringId: recurringId,
        TransactionColumns.savingId: savingId,
        TransactionColumns.createdAt: '2026-10-26T10:00:00.000',
      };

  Map<String, Object?> insuranceRule({int? id}) => <String, Object?>{
        RecurringColumns.id: ?id,
        RecurringColumns.label: 'Insurance',
        RecurringColumns.amountMinor: 100000,
        RecurringColumns.kind: EntryKindValues.saved,
        RecurringColumns.categoryId: 11,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
      };

  group('migration 005 (BR-19, BR-11, BR-17, D191)', () {
    test('a new database has the two hidden not logged rows, archived, out and in', () async {
      final Database db = (await openTestDatabase()).db;

      final List<Map<String, Object?>> rows = await db.query(
        Tables.categories,
        where: '${CategoryColumns.key} IN (?, ?)',
        whereArgs: <Object?>['not_logged', 'not_logged_in'],
        orderBy: CategoryColumns.id,
      );

      expect(rows.map((Map<String, Object?> r) => r[CategoryColumns.key]), <String>['not_logged', 'not_logged_in']);
      expect(rows.map((Map<String, Object?> r) => r[CategoryColumns.kind]), <String>[EntryKindValues.spent, EntryKindValues.got]);
      expect(rows.map((Map<String, Object?> r) => r[CategoryColumns.archived]), <int>[1, 1]);
      expect('not_logged', CategoryKeys.notLogged);
      expect('not_logged_in', CategoryKeys.notLoggedIn);
    });

    test('upgrading a v4 database keeps every entry, id, link, created time and index', () async {
      final AppDatabase upgraded = await reopen(await versionFile(4, rentAndEntries));
      final Database db = upgraded.db;

      expect((await db.rawQuery('PRAGMA user_version')).single.values.single, 5);
      final List<Map<String, Object?>> entries = await db.query(Tables.transactions, orderBy: TransactionColumns.id);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.id]), <int>[2, 3]);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.recurringId]), <int?>[2, null]);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.savingId]), <int?>[null, null]);
      expect(entries.last[TransactionColumns.note], 'Chai');
      expect(
        entries.map((Map<String, Object?> e) => e[TransactionColumns.createdAt]),
        <String>['2026-10-05T00:01:00.000', '2026-10-26T10:05:00.000'],
      );
      expect(
        await indexNames(db),
        containsAll(<String>[
          'ix_transactions_date',
          'ix_transactions_category_date',
          'ux_transactions_recurring_date',
          'ix_transactions_saving',
        ]),
      );
      final List<Object?> linked =
          (await db.rawQuery('PRAGMA foreign_key_list(${Tables.transactions})')).map((Map<String, Object?> r) => r['table']).toList();
      expect(linked, containsAll(<String>[Tables.recurring, Tables.categories]));
    });

    test('a v4 database gains the rows with ids after its own', () async {
      final AppDatabase upgraded = await reopen(await versionFile(4, (Database db) async {}));

      final List<Map<String, Object?>> categories = await upgraded.db.query(Tables.categories, orderBy: CategoryColumns.id);

      expect(categories, hasLength(14));
      expect(categories[12][CategoryColumns.id], 13);
      expect(categories[12][CategoryColumns.key], 'not_logged');
      expect(categories[13][CategoryColumns.id], 14);
      expect(categories[13][CategoryColumns.key], 'not_logged_in');
    });

    test('a key that already exists is not added twice', () async {
      final AppDatabase upgraded = await reopen(await versionFile(4, (Database db) async {
        await db.insert(Tables.categories, <String, Object?>{
          CategoryColumns.key: 'not_logged',
          CategoryColumns.iconKey: 'not_logged',
          CategoryColumns.kind: EntryKindValues.spent,
          CategoryColumns.sort: 20,
          CategoryColumns.archived: 1,
        });
      }));

      final List<Map<String, Object?>> rows =
          await upgraded.db.query(Tables.categories, where: "${CategoryColumns.key} = 'not_logged'");

      expect(rows, hasLength(1));
      expect(rows.single[CategoryColumns.sort], 20);
    });

    test('upgrading from v1 and from v3 files still works', () async {
      for (final int version in <int>[1, 3]) {
        final AppDatabase upgraded = await reopen(await versionFile(version, (Database db) async {}));

        expect((await upgraded.db.rawQuery('PRAGMA user_version')).single.values.single, 5, reason: 'from v$version');
        expect(await upgraded.db.query(Tables.categories, where: "${CategoryColumns.key} = 'not_logged_in'"), hasLength(1));
      }
    });

    test('a kind of used with a saving_id is accepted; an unknown kind is refused', () async {
      final Database db = (await openTestDatabase()).db;
      final int saving = await db.insert(Tables.recurring, insuranceRule());

      expect(await db.insert(Tables.transactions, entryRow(savingId: saving)), greaterThan(0));
      await expectLater(db.insert(Tables.transactions, entryRow(kind: 'gift')), throwsA(isA<DatabaseException>()));
    });

    test('a used entry and a saved entry may share a date and a rule id', () async {
      final Database db = (await openTestDatabase()).db;
      final int saving = await db.insert(Tables.recurring, insuranceRule());
      await db.insert(Tables.transactions, entryRow(kind: EntryKindValues.saved, recurringId: saving, date: '2026-10-05'));

      await db.insert(Tables.transactions, entryRow(savingId: saving, date: '2026-10-05'));
      await db.insert(Tables.transactions, entryRow(savingId: saving, date: '2026-10-05'));

      expect(await db.query(Tables.transactions), hasLength(3));
      await expectLater(
        db.insert(Tables.transactions, entryRow(kind: EntryKindValues.saved, recurringId: saving, date: '2026-10-05')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('a used entry links to a rule that exists', () async {
      final Database db = (await openTestDatabase()).db;

      await expectLater(db.insert(Tables.transactions, entryRow(savingId: 999)), throwsA(isA<DatabaseException>()));
    });

    test('suggestion_state gains a nullable asked_on and keeps its rows', () async {
      final AppDatabase upgraded = await reopen(await versionFile(4, (Database db) async {
        await db.insert(Tables.suggestionState, <String, Object?>{
          SuggestionStateColumns.categoryId: 1,
          SuggestionStateColumns.quietOn: '2026-10-26',
          SuggestionStateColumns.restUntil: '2026-11-26',
          SuggestionStateColumns.forgottenAt: '2026-10-26T09:00:00.000',
        });
      }));

      final Map<String, Object?> row = (await upgraded.db.query(Tables.suggestionState)).single;

      expect(row[SuggestionStateColumns.quietOn], '2026-10-26');
      expect(row[SuggestionStateColumns.restUntil], '2026-11-26');
      expect(row[SuggestionStateColumns.forgottenAt], '2026-10-26T09:00:00.000');
      expect(row.containsKey(SuggestionStateColumns.askedOn), isTrue);
      expect(row[SuggestionStateColumns.askedOn], isNull);
    });

    test('foreign_key_check is empty after the upgrade', () async {
      final AppDatabase upgraded = await reopen(await versionFile(4, rentAndEntries));

      expect(await upgraded.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    });
  });

  group('backup files across schema v5 (BR-16, E101, NFR-5)', () {
    late AppDatabase database;
    late SqfliteBackupLocalDataSource source;

    setUp(() async {
      database = await openTestDatabase();
      source = SqfliteBackupLocalDataSource(database: database, scratch: databaseFactoryFfi);
    });

    test('a v4 backup file restores: its rows load, migrate to 5 and gain the hidden rows', () async {
      final Database v4 = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          singleInstance: false,
          version: 4,
          onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 4),
        ),
      );
      addTearDown(v4.close);
      await seedMoney(v4);
      final List<Map<String, Object?>> names =
          await v4.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'");
      final TableRows old = <String, List<Map<String, Object?>>>{
        for (final Map<String, Object?> row in names) row['name']! as String: await v4.query(row['name']! as String, orderBy: 'rowid'),
      };

      final TableRows upgraded = await source.upgrade(4, old);

      expect(upgraded[Tables.transactions]!.single[TransactionColumns.note], 'chai ☕ with Ravi');
      expect(upgraded[Tables.transactions]!.single.containsKey(TransactionColumns.savingId), isTrue);
      expect(
        upgraded[Tables.categories]!.map((Map<String, Object?> r) => r[CategoryColumns.key]),
        containsAll(<String>['not_logged', 'not_logged_in']),
      );
      await source.replace(upgraded, const <String, String>{});
      expect((await source.dump())[Tables.transactions], hasLength(1));
    });

    test('a v5 backup round-trips used, saving_id and asked_on', () async {
      await seedMoney(database.db);
      await database.db.insert(Tables.recurring, insuranceRule(id: 5));
      await database.db.insert(Tables.transactions, entryRow(savingId: 5));
      await database.db.insert(Tables.suggestionState, <String, Object?>{
        SuggestionStateColumns.categoryId: 1,
        SuggestionStateColumns.askedOn: '2026-10-26',
      });
      final TableRows before = await source.dump();
      await database.db.delete(Tables.transactions);
      await database.db.delete(Tables.suggestionState);

      await source.replace(before, const <String, String>{});

      expect(await source.dump(), before);
      expect((await source.dump())[Tables.suggestionState]!.single[SuggestionStateColumns.askedOn], '2026-10-26');
    });

    test('Delete everything leaves only the fresh hidden rows', () async {
      await seedMoney(database.db);
      await database.db.insert(Tables.recurring, insuranceRule(id: 5));
      await database.db.insert(Tables.transactions, entryRow(savingId: 5));
      await database.db.insert(
        Tables.settings,
        <String, Object?>{SettingsColumns.key: SettingKeys.installLineSeen, SettingsColumns.value: '1'},
      );

      await source.replace(await source.fresh(), const <String, String>{});

      final TableRows after = await source.dump();
      expect(after[Tables.transactions], isEmpty);
      expect(after[Tables.recurring], isEmpty);
      expect(
        after[Tables.settings]!.map((Map<String, Object?> r) => r[SettingsColumns.key]),
        isNot(contains(SettingKeys.installLineSeen)),
      );
      expect(after, await source.fresh());
    });

    test('install_line_seen is not a local setting, so a backup carries it', () {
      expect(SqfliteBackupLocalDataSource.localSettings, isNot(contains(SettingKeys.installLineSeen)));
    });
  });
}
