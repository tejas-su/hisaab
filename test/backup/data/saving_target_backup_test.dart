import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/backup/data/datasource/backup_local_data_source.dart';
import 'package:hisaab/backup/data/mapper/backup_json_mapper.dart';
import 'package:hisaab/backup/data/repository/backup_repository_impl.dart';
import 'package:hisaab/backup/domain/entities/backup_file.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/db/migrations/migrations.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fakes/fake_backup_files.dart';
import '../../helpers/fixtures/backup/backup_rows.dart';
import '../../helpers/test_database.dart';

const CalendarDate _today = CalendarDate(2026, 11, 23);
final DateTime _restoreAt = DateTime(2026, 11, 23, 10);

void main() {
  late AppDatabase database;
  late SqfliteBackupLocalDataSource source;
  late FakeBackupFiles files;
  late BackupRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    source = SqfliteBackupLocalDataSource(database: database, scratch: databaseFactoryFfi);
    files = FakeBackupFiles();
    repository = BackupRepositoryImpl(source: source, files: files);
    await seedMoney(database.db);
  });

  Future<void> restoreFile(int version, TableRows tables) async {
    files.picked = Option<Uint8List>.of(
      BackupJsonMapper.encode(BackupFile(schemaVersion: version, madeOn: _today, tables: tables, entryCount: 0)),
    );
    final BackupFile file =
        (await repository.pick().run()).getOrElse((Failure f) => fail(f.message)).getOrElse(() => fail('cancelled'));
    final Either<Failure, Unit> restored = await repository.restore(file, at: _restoreAt, keepUndo: false).run();
    expect(restored.isRight(), isTrue);
  }

  Future<TableRows> dump(Database db) async {
    final List<Map<String, Object?>> names =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'");
    return <String, List<Map<String, Object?>>>{
      for (final Map<String, Object?> row in names) row['name']! as String: await db.query(row['name']! as String, orderBy: 'rowid'),
    };
  }

  group('saving target in a backup (BR-23, BR-16)', () {
    test('the backup is written at schema version 7', () async {
      await repository.backUp(_today).run();

      final BackupFile file =
          BackupJsonMapper.decode(files.saved.single.$2, currentVersion: AppDatabase.schemaVersion).getRight().toNullable()!;
      expect(file.schemaVersion, 7);
    });

    test('a backup round trip carries the three target columns', () async {
      final AppDatabase other = await openTestDatabase();
      await seedMoney(other.db);
      await other.db.insert(Tables.recurring, <String, Object?>{
        RecurringColumns.id: 70,
        RecurringColumns.label: 'Bike',
        RecurringColumns.amountMinor: 100000,
        RecurringColumns.kind: EntryKindValues.saved,
        RecurringColumns.categoryId: 11,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
        RecurringColumns.targetMinor: 500000,
        RecurringColumns.targetReachedFor: 500000,
        RecurringColumns.targetReachedOn: '2026-11-20',
      });
      await restoreFile(AppDatabase.schemaVersion, await dump(other.db));

      final Map<String, Object?> row =
          (await database.db.query(Tables.recurring, where: '${RecurringColumns.id} = 70')).single;
      expect(row[RecurringColumns.targetMinor], 500000);
      expect(row[RecurringColumns.targetReachedFor], 500000);
      expect(row[RecurringColumns.targetReachedOn], '2026-11-20');
    });

    test('a v6 backup file restores with all three target columns null', () async {
      final Database v6 = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false, version: 6, onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 6)),
      );
      addTearDown(v6.close);
      await seedMoney(v6);
      await v6.insert(Tables.recurring, <String, Object?>{
        RecurringColumns.id: 71,
        RecurringColumns.label: 'Bike',
        RecurringColumns.amountMinor: 100000,
        RecurringColumns.kind: EntryKindValues.saved,
        RecurringColumns.categoryId: 11,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
      });

      await restoreFile(6, await dump(v6));

      final Map<String, Object?> row =
          (await database.db.query(Tables.recurring, where: '${RecurringColumns.id} = 71')).single;
      expect(row[RecurringColumns.label], 'Bike');
      expect(row[RecurringColumns.targetMinor], isNull);
      expect(row[RecurringColumns.targetReachedFor], isNull);
      expect(row[RecurringColumns.targetReachedOn], isNull);
    });
  });
}
