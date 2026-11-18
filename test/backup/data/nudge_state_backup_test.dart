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

const CalendarDate _today = CalendarDate(2026, 11, 18);
final DateTime _restoreAt = DateTime(2026, 11, 18, 10);

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

  Future<void> putNudge(AppDatabase db, int id, {String? armedFor, int streak = 0, String? restUntil}) =>
      db.db.insert(Tables.nudgeState, <String, Object?>{
        NudgeStateColumns.categoryId: id,
        NudgeStateColumns.armedFor: armedFor,
        NudgeStateColumns.ignoredStreak: streak,
        NudgeStateColumns.restUntil: restUntil,
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

  Future<void> restoreFrom(AppDatabase other) async => restoreFile(
        AppDatabase.schemaVersion,
        await SqfliteBackupLocalDataSource(database: other, scratch: databaseFactoryFfi).dump(),
      );

  group('nudge_state in a backup (BR-22.12, BR-16)', () {
    test('the backup is written at schema version 6 and lists nudge_state', () async {
      await repository.backUp(_today).run();

      final BackupFile file =
          BackupJsonMapper.decode(files.saved.single.$2, currentVersion: AppDatabase.schemaVersion).getRight().toNullable()!;
      expect(file.schemaVersion, 6);
      expect(file.tables[Tables.nudgeState], isEmpty);
    });

    test('a backup round trip carries the nudge rows, the general (0) one included', () async {
      final AppDatabase other = await openTestDatabase();
      await seedMoney(other.db);
      await putNudge(other, 0, armedFor: '2026-11-18T20:30:00.000', streak: 2);
      await putNudge(other, 1, restUntil: '2026-11-25');

      await restoreFrom(other);

      expect(await database.db.query(Tables.nudgeState, orderBy: NudgeStateColumns.categoryId), <Map<String, Object?>>[
        <String, Object?>{'category_id': 0, 'armed_for': '2026-11-18T20:30:00.000', 'ignored_streak': 2, 'rest_until': null},
        <String, Object?>{'category_id': 1, 'armed_for': null, 'ignored_streak': 0, 'rest_until': '2026-11-25'},
      ]);
    });

    test('E124: an armed_for in the past or the future is stored as it came', () async {
      final AppDatabase other = await openTestDatabase();
      await seedMoney(other.db);
      await putNudge(other, 0, armedFor: '2020-01-01T08:00:00.000');
      await putNudge(other, 1, armedFor: '2099-01-01T08:00:00.000');

      await restoreFrom(other);

      final List<Map<String, Object?>> rows = await database.db.query(Tables.nudgeState, orderBy: NudgeStateColumns.categoryId);
      expect(
        rows.map((Map<String, Object?> r) => r[NudgeStateColumns.armedFor]),
        <String>['2020-01-01T08:00:00.000', '2099-01-01T08:00:00.000'],
      );
    });

    test('a v5 backup file restores as before and leaves nudge_state empty', () async {
      await putNudge(database, 1, streak: 3);
      final Database v5 = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false, version: 5, onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 5)),
      );
      addTearDown(v5.close);
      await seedMoney(v5);
      final List<Map<String, Object?>> names =
          await v5.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'");
      final TableRows old = <String, List<Map<String, Object?>>>{
        for (final Map<String, Object?> row in names) row['name']! as String: await v5.query(row['name']! as String, orderBy: 'rowid'),
      };
      expect(old.containsKey(Tables.nudgeState), isFalse);

      await restoreFile(5, old);

      expect(await source.entryCount(), 1);
      expect(await database.db.query(Tables.nudgeState), isEmpty);
    });

    test('Delete everything empties nudge_state', () async {
      await putNudge(database, 0, armedFor: '2026-11-18T20:30:00.000', streak: 1);

      await repository.wipe().run();

      expect(await database.db.query(Tables.nudgeState), isEmpty);
    });
  });
}
