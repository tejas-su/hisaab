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

  Map<String, Object?> savingRule({int? id, int? targetMinor}) => <String, Object?>{
        RecurringColumns.id: ?id,
        RecurringColumns.label: 'Insurance',
        RecurringColumns.amountMinor: 100000,
        RecurringColumns.kind: EntryKindValues.saved,
        RecurringColumns.categoryId: 11,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
        RecurringColumns.targetMinor: targetMinor,
      };

  group('migration 007 (BR-23)', () {
    test('the schema is at version 7', () {
      expect(migrations, hasLength(7));
      expect(AppDatabase.schemaVersion, 7);
    });

    test('a new database has the three target columns on recurring', () async {
      final Database db = (await openTestDatabase()).db;

      final List<Map<String, Object?>> columns = await db.rawQuery('PRAGMA table_info(${Tables.recurring})');
      final List<Object?> names = columns.map((Map<String, Object?> c) => c['name']).toList();
      expect(names, containsAll(<String>['target_minor', 'target_reached_for', 'target_reached_on']));
    });

    test('upgrading a v6 database keeps a saving row and leaves all three columns null', () async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_v6');
      addTearDown(() => dir.delete(recursive: true));
      final String path = p.join(dir.path, AppDatabase.fileName);
      final Database old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 6,
          onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 6),
        ),
      );
      await old.insert(Tables.recurring, <String, Object?>{
        RecurringColumns.id: 5,
        RecurringColumns.label: 'Insurance',
        RecurringColumns.amountMinor: 100000,
        RecurringColumns.kind: EntryKindValues.saved,
        RecurringColumns.categoryId: 11,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
      });
      await old.close();

      final Either<Failure, AppDatabase> opened =
          await AppDatabase.open(factory: databaseFactoryFfi, path: path, singleInstance: false).run();
      final AppDatabase upgraded = opened.getOrElse((Failure failure) => fail(failure.message));
      addTearDown(upgraded.close);
      final Database db = upgraded.db;

      expect((await db.rawQuery('PRAGMA user_version')).single.values.single, 7);
      final Map<String, Object?> row = (await db.query(Tables.recurring, where: '${RecurringColumns.id} = 5')).single;
      expect(row[RecurringColumns.label], 'Insurance');
      expect(row[RecurringColumns.targetMinor], isNull);
      expect(row[RecurringColumns.targetReachedFor], isNull);
      expect(row[RecurringColumns.targetReachedOn], isNull);
    });

    test('a positive target_minor is stored', () async {
      final Database db = (await openTestDatabase()).db;

      await db.insert(Tables.recurring, savingRule(id: 50, targetMinor: 500000));

      expect((await db.query(Tables.recurring, where: '${RecurringColumns.id} = 50')).single[RecurringColumns.targetMinor], 500000);
    });

    test('a target_minor of 0 is rejected by the CHECK constraint', () async {
      final Database db = (await openTestDatabase()).db;

      await expectLater(db.insert(Tables.recurring, savingRule(targetMinor: 0)), throwsA(isA<DatabaseException>()));
    });
  });
}
