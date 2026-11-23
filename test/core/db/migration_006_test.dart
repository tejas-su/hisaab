import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/db/migrations/migrations.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

void main() {
  sqfliteFfiInit();

  group('migration 006 (BR-22.12)', () {
    test('the schema is at version 6', () {
      expect(migrations, hasLength(7));
      expect(AppDatabase.schemaVersion, 7);
    });

    test('a new database has an empty nudge_state with the four columns and no foreign key', () async {
      final Database db = (await openTestDatabase()).db;

      expect(await db.query(Tables.nudgeState), isEmpty);
      final List<Map<String, Object?>> columns = await db.rawQuery('PRAGMA table_info(${Tables.nudgeState})');
      expect(
        columns.map((Map<String, Object?> c) => c['name']),
        <String>['category_id', 'armed_for', 'ignored_streak', 'rest_until'],
      );
      expect(await db.rawQuery('PRAGMA foreign_key_list(${Tables.nudgeState})'), isEmpty);
    });

    test('upgrading a v5 database keeps every old table and row and adds nudge_state', () async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_v5');
      addTearDown(() => dir.delete(recursive: true));
      final String path = p.join(dir.path, AppDatabase.fileName);
      final Database old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 5),
        ),
      );
      await old.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.id: 9,
        TransactionColumns.amountMinor: 2000,
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: 1,
        TransactionColumns.date: '2026-10-26',
        TransactionColumns.note: 'Chai',
        TransactionColumns.createdAt: '2026-10-26T10:05:00.000',
      });
      await old.insert(Tables.suggestionState, <String, Object?>{
        SuggestionStateColumns.categoryId: 1,
        SuggestionStateColumns.quietOn: '2026-10-26',
      });
      final int categories = (await old.query(Tables.categories)).length;
      await old.close();

      final Either<Failure, AppDatabase> opened =
          await AppDatabase.open(factory: databaseFactoryFfi, path: path, singleInstance: false).run();
      final AppDatabase upgraded = opened.getOrElse((Failure failure) => fail(failure.message));
      addTearDown(upgraded.close);
      final Database db = upgraded.db;

      expect((await db.rawQuery('PRAGMA user_version')).single.values.single, 7);
      expect((await db.query(Tables.transactions)).single[TransactionColumns.note], 'Chai');
      expect((await db.query(Tables.suggestionState)).single[SuggestionStateColumns.quietOn], '2026-10-26');
      expect(await db.query(Tables.categories), hasLength(categories));
      expect(await db.query(Tables.nudgeState), isEmpty);
    });
  });
}
