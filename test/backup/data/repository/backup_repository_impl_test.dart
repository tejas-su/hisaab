import 'dart:convert';
import 'dart:typed_data';

import 'package:expense_tracker/backup/data/datasource/backup_local_data_source.dart';
import 'package:expense_tracker/backup/data/mapper/backup_json_mapper.dart';
import 'package:expense_tracker/backup/data/repository/backup_repository_impl.dart';
import 'package:expense_tracker/backup/domain/backup_failures.dart';
import 'package:expense_tracker/backup/domain/entities/backup_file.dart';
import 'package:expense_tracker/backup/domain/entities/backup_status.dart';
import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/db/migrations/migrations.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fakes/fake_backup_files.dart';
import '../../../helpers/fixtures/backup/backup_rows.dart';
import '../../../helpers/test_database.dart';

const CalendarDate _today = CalendarDate(2026, 11, 6);
final DateTime _restoreAt = DateTime(2026, 11, 6, 10);

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

  /// A backup file from another phone that holds [entries] entries.
  Future<Uint8List> otherPhoneBackup({int entries = 2}) async {
    final AppDatabase other = await openTestDatabase();
    await seedMoney(other.db);
    for (int i = 0; i < entries - 1; i++) {
      await other.db.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.amountMinor: 5000 + i,
        TransactionColumns.kind: 'out',
        TransactionColumns.categoryId: 2,
        TransactionColumns.date: '2026-10-1$i',
        TransactionColumns.createdAt: '2026-10-1${i}T08:00:00.000',
      });
    }
    final TableRows rows = await SqfliteBackupLocalDataSource(database: other, scratch: databaseFactoryFfi).dump();
    return BackupJsonMapper.encode(
      BackupFile(schemaVersion: AppDatabase.schemaVersion, madeOn: const CalendarDate(2026, 10, 12), tables: rows, entryCount: entries),
    );
  }

  Future<BackupFile> pickOk() async =>
      (await repository.pick().run()).getOrElse((Failure f) => fail(f.message)).getOrElse(() => fail('cancelled'));

  group('BackupRepositoryImpl', () {
    group('backUp (FR-SE-4 AC-2)', () {
      test('saves a dated file holding everything and remembers the day', () async {
        final Either<Failure, Option<BackedUp>> result = await repository.backUp(_today).run();

        expect(result.getRight().toNullable()?.isSome(), isTrue);
        expect(files.saved.single.$1, 'hisaab-backup-2026-11-06.json');
        final BackupFile file = BackupJsonMapper.decode(files.saved.single.$2, currentVersion: AppDatabase.schemaVersion)
            .getOrElse((Failure f) => fail(f.message));
        expect(file.entryCount, 1);
        expect(file.madeOn, _today);
        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.of('2026-11-06'));
      });

      test('a cancelled Save to screen changes nothing (E35)', () async {
        files.saveAnswer = const Option<BackedUp>.none();

        final Either<Failure, Option<BackedUp>> result = await repository.backUp(_today).run();

        expect(result, Either<Failure, Option<BackedUp>>.right(const Option<BackedUp>.none()));
        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.none());
      });

      test('a failed write is a write failure and keeps the old day (E36)', () async {
        await source.writeSetting(SettingKeys.lastBackup, '2026-10-12');
        files.error = StateError('disk full');

        final Either<Failure, Option<BackedUp>> result = await repository.backUp(_today).run();

        expect(result.getLeft().toNullable(), isA<BackupWriteFailure>());
        expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.of('2026-10-12'));
      });
    });

    group('pick (BR-16, E14)', () {
      test('a cancelled pick is None', () async {
        expect((await repository.pick().run()).getRight().toNullable(), const Option<BackupFile>.none());
      });

      test('an unreadable file is an open failure (E37)', () async {
        files.error = StateError('gone');

        expect((await repository.pick().run()).getLeft().toNullable(), isA<BackupOpenFailure>());
      });

      test('a file that is not a backup is refused', () async {
        files.picked = Option<Uint8List>.of(utf8.encode('hello'));

        expect((await repository.pick().run()).getLeft().toNullable(), isA<NotABackupFailure>());
      });

      test('a backup from a newer hisaab is refused', () async {
        files.picked = Option<Uint8List>.of(
          utf8.encode(jsonEncode(<String, Object?>{'app': 'hisaab', 'schemaVersion': AppDatabase.schemaVersion + 1})),
        );

        expect((await repository.pick().run()).getLeft().toNullable(), isA<NewerBackupFailure>());
      });

      test('a valid backup comes back with its date and entry count, changing nothing', () async {
        files.picked = Option<Uint8List>.of(await otherPhoneBackup(entries: 3));
        final TableRows before = await source.dump();

        final BackupFile file = await pickOk();

        expect(file.madeOn, const CalendarDate(2026, 10, 12));
        expect(file.entryCount, 3);
        expect(await source.dump(), before);
      });

      test('an older backup is brought up to the current schema', () async {
        final Database v1 = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false, version: 1, onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 1)),
        );
        addTearDown(v1.close);
        await seedMoney(v1);
        final TableRows old = <String, List<Map<String, Object?>>>{
          for (final String t in <String>[Tables.categories, Tables.recurring, Tables.transactions, Tables.settings]) t: await v1.query(t),
        };
        files.picked = Option<Uint8List>.of(
          BackupJsonMapper.encode(BackupFile(schemaVersion: 1, madeOn: _today, tables: old, entryCount: 1)),
        );

        final BackupFile file = await pickOk();

        expect(file.schemaVersion, AppDatabase.schemaVersion);
        expect(file.tables[Tables.recurring]!.first[RecurringColumns.amountMode], AmountModeValues.fixed);
      });

      test('rows that do not fit the schema are broken', () async {
        final TableRows rows = await source.dump();
        files.picked = Option<Uint8List>.of(
          BackupJsonMapper.encode(
            BackupFile(
              schemaVersion: AppDatabase.schemaVersion,
              madeOn: _today,
              tables: <String, List<Map<String, Object?>>>{
                ...rows,
                Tables.categories: <Map<String, Object?>>[
                  <String, Object?>{'id': 1, 'shade': 'blue'},
                ],
              },
              entryCount: 1,
            ),
          ),
        );

        expect((await repository.pick().run()).getLeft().toNullable(), isA<BrokenBackupFailure>());
      });
    });

    group('restore and undo (BR-16, E42)', () {
      test('replaces everything, keeps the last-backup day and offers undo', () async {
        await source.writeSetting(SettingKeys.lastBackup, '2026-11-01');
        files.picked = Option<Uint8List>.of(await otherPhoneBackup(entries: 3));
        final BackupFile file = await pickOk();

        await repository.restore(file, at: _restoreAt, keepUndo: true).run();

        expect(await source.entryCount(), 3);
        final BackupStatus status = (await repository.status(_today).run()).getOrElse((Failure f) => fail(f.message));
        expect(status.lastBackedUp, const Option<CalendarDate>.of(CalendarDate(2026, 11, 1)));
        expect(status.undo, const Option<RestoreUndo>.of(RestoreUndo(restoredOn: _today, addedSince: 0)));
      });

      test('from onboarding it keeps no undo', () async {
        files.picked = Option<Uint8List>.of(await otherPhoneBackup());

        await repository.restore(await pickOk(), at: _restoreAt, keepUndo: false).run();

        final BackupStatus status = (await repository.status(_today).run()).getOrElse((Failure f) => fail(f.message));
        expect(status.undo, const Option<RestoreUndo>.none());
      });

      test('counts the entries added since, and undo puts the old data back exactly', () async {
        final TableRows before = await source.dump();
        files.picked = Option<Uint8List>.of(await otherPhoneBackup());
        await repository.restore(await pickOk(), at: _restoreAt, keepUndo: true).run();
        await database.db.insert(Tables.transactions, <String, Object?>{
          TransactionColumns.amountMinor: 9900,
          TransactionColumns.kind: 'out',
          TransactionColumns.categoryId: 1,
          TransactionColumns.date: '2026-11-06',
          TransactionColumns.createdAt: '2026-11-06T11:00:00.000',
        });
        final BackupStatus after = (await repository.status(_today).run()).getOrElse((Failure f) => fail(f.message));
        expect(after.undo.toNullable()?.addedSince, 1);

        final Either<Failure, Unit> undone = await repository.undoRestore().run();

        expect(undone.isRight(), isTrue);
        expect(await source.dump(), before);
        final BackupStatus status = (await repository.status(_today).run()).getOrElse((Failure f) => fail(f.message));
        expect(status.undo, const Option<RestoreUndo>.none());
      });

      test('undo with nothing to undo fails', () async {
        expect((await repository.undoRestore().run()).getLeft().toNullable(), isA<InvalidDataFailure>());
      });

      test('the undo lasts 6 days and is dropped on the 7th', () async {
        files.picked = Option<Uint8List>.of(await otherPhoneBackup());
        await repository.restore(await pickOk(), at: _restoreAt, keepUndo: true).run();

        final BackupStatus day6 = (await repository.status(_today.addDays(6)).run()).getOrElse((Failure f) => fail(f.message));
        final BackupStatus day7 = (await repository.status(_today.addDays(7)).run()).getOrElse((Failure f) => fail(f.message));

        expect(day6.undo.isSome(), isTrue);
        expect(day7.undo, const Option<RestoreUndo>.none());
        expect(await source.readSetting(SettingKeys.restoreSnapshot), const Option<String>.none());
      });

      test('a failed replace changes nothing (E38)', () async {
        final TableRows before = await source.dump();
        const BackupFile broken = BackupFile(
          schemaVersion: 3,
          madeOn: _today,
          tables: <String, List<Map<String, Object?>>>{
            'mystery': <Map<String, Object?>>[
              <String, Object?>{'id': 1},
            ],
          },
          entryCount: 0,
        );

        final Either<Failure, Unit> result = await repository.restore(broken, at: _restoreAt, keepUndo: true).run();

        expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
        expect(await source.dump(), before);
      });
    });

    group('status', () {
      test('has no backup and no undo on a new phone', () async {
        expect(
          (await repository.status(_today).run()).getRight().toNullable(),
          const BackupStatus(lastBackedUp: Option<CalendarDate>.none(), undo: Option<RestoreUndo>.none()),
        );
      });
    });

    test('entryCount counts the entries here', () async {
      expect((await repository.entryCount().run()).getRight().toNullable(), 1);
    });

    test('wipe leaves a fresh install, with no backup day or undo (FR-SE-4 AC-8)', () async {
      await source.writeSetting(SettingKeys.lastBackup, '2026-11-01');
      await source.writeSetting(SettingKeys.restoreSnapshot, '{}');
      await source.writeSetting(SettingKeys.restoredAt, '2026-11-05T10:00:00.000');

      await repository.wipe().run();

      expect(await source.dump(), await source.fresh());
      expect(await source.readSetting(SettingKeys.lastBackup), const Option<String>.none());
      expect(await source.readSetting(SettingKeys.onboardingDone), const Option<String>.none());
    });
  });
}
