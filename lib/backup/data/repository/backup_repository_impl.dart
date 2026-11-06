import 'dart:convert';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/backup_failures.dart';
import '../../domain/entities/backup_file.dart';
import '../../domain/entities/backup_status.dart';
import '../../domain/repository/backup_repository.dart';
import '../datasource/backup_local_data_source.dart';
import '../mapper/backup_json_mapper.dart';
import '../platform/backup_files.dart';

/// [BackupRepository] over the database and Android's file screens.
final class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl({required this._source, required this._files});

  final BackupLocalDataSource _source;
  final BackupFiles _files;

  /// How long *Undo restore* stays (SPEC BR-16).
  static const int undoDays = 7;

  @override
  TaskEither<Failure, BackupStatus> status(CalendarDate today) => dbTask(() async {
        final Option<CalendarDate> last = (await _source.readSetting(SettingKeys.lastBackup)).flatMap(_day);
        return BackupStatus(lastBackedUp: last, undo: await _undo(today));
      });

  @override
  TaskEither<Failure, Option<BackedUp>> backUp(CalendarDate today) => dbTask(() => _current(today))
      .flatMap(
        (BackupFile file) => TaskEither<Failure, Option<BackedUp>>.tryCatch(
          () => _files.save(BackupJsonMapper.encode(file), 'hisaab-backup-${today.toIso()}.json'),
          (Object error, StackTrace _) => BackupWriteFailure(error.toString()),
        ),
      )
      .flatMap(
        (Option<BackedUp> saved) => dbTask(() async {
          if (saved.isSome()) {
            await _source.writeSetting(SettingKeys.lastBackup, today.toIso());
          }
          return saved;
        }),
      );

  @override
  TaskEither<Failure, Option<BackupFile>> pick() => TaskEither<Failure, Option<Uint8List>>.tryCatch(
        _files.open,
        (Object error, StackTrace _) => BackupOpenFailure(error.toString()),
      ).flatMap(
        (Option<Uint8List> bytes) => bytes.match(
          () => TaskEither<Failure, Option<BackupFile>>.right(const Option<BackupFile>.none()),
          (Uint8List read) => _read(read).map(Option<BackupFile>.of),
        ),
      );

  @override
  TaskEither<Failure, int> entryCount() => dbTask(_source.entryCount);

  @override
  TaskEither<Failure, Unit> restore(BackupFile file, {required DateTime at, required bool keepUndo}) => dbTask(() async {
        final Map<String, String> local = await _kept();
        if (keepUndo) {
          final BackupFile before = await _current(CalendarDate.fromDateTime(at));
          local[SettingKeys.restoreSnapshot] = utf8.decode(BackupJsonMapper.encode(before));
          local[SettingKeys.restoredAt] = at.toIso8601String();
        }
        await _source.replace(file.tables, local);
        return unit;
      });

  @override
  TaskEither<Failure, Unit> undoRestore() => dbTask(() => _source.readSetting(SettingKeys.restoreSnapshot)).flatMap(
        (Option<String> snapshot) => snapshot.match(
          () => TaskEither<Failure, Unit>.left(const InvalidDataFailure('no restore to undo')),
          (String json) => _read(utf8.encode(json)).flatMap(
            (BackupFile before) => dbTask(() async {
              // why: the replace clears the snapshot and its time with every other setting.
              await _source.replace(before.tables, await _kept());
              return unit;
            }),
          ),
        ),
      );

  @override
  TaskEither<Failure, Unit> wipe() => dbTask(() async {
        await _source.replace(await _source.fresh(), const <String, String>{});
        return unit;
      });

  TaskEither<Failure, BackupFile> _read(List<int> bytes) => TaskEither<Failure, BackupFile>.fromEither(
        BackupJsonMapper.decode(bytes, currentVersion: AppDatabase.schemaVersion),
      ).flatMap(
        (BackupFile file) => TaskEither<Failure, BackupFile>.tryCatch(
          () async {
            final TableRows tables = await _source.upgrade(file.schemaVersion, file.tables);
            return BackupFile(
              schemaVersion: AppDatabase.schemaVersion,
              madeOn: file.madeOn,
              tables: tables,
              entryCount: tables[Tables.transactions]?.length ?? 0,
            );
          },
          (Object error, StackTrace _) => BrokenBackupFailure(error.toString()),
        ),
      );

  Future<BackupFile> _current(CalendarDate today) async {
    final TableRows tables = await _source.dump();
    return BackupFile(
      schemaVersion: AppDatabase.schemaVersion,
      madeOn: today,
      tables: tables,
      entryCount: tables[Tables.transactions]?.length ?? 0,
    );
  }

  /// The local settings a restore keeps: the last backup made on this phone.
  Future<Map<String, String>> _kept() async => (await _source.readSetting(SettingKeys.lastBackup)).match(
        () => <String, String>{},
        (String day) => <String, String>{SettingKeys.lastBackup: day},
      );

  Future<Option<RestoreUndo>> _undo(CalendarDate today) async {
    final Option<String> at = await _source.readSetting(SettingKeys.restoredAt);
    final bool kept = (await _source.readSetting(SettingKeys.restoreSnapshot)).isSome();
    final Option<(String, CalendarDate)> restore = at
        .filter((String _) => kept)
        .flatMap((String iso) => _dayOfInstant(iso).map((CalendarDate day) => (iso, day)));
    switch (restore) {
      case Some(value: (final String iso, final CalendarDate day)) when day.addDays(undoDays).isAfter(today):
        return Option<RestoreUndo>.of(RestoreUndo(restoredOn: day, addedSince: await _source.entriesCreatedAfter(iso)));
      case Some():
        await _source.removeSettings(<String>{SettingKeys.restoreSnapshot, SettingKeys.restoredAt});
        return const Option<RestoreUndo>.none();
      case None():
        return const Option<RestoreUndo>.none();
    }
  }

  static Option<CalendarDate> _day(String iso) => CalendarDate.parse(iso).toOption();

  static Option<CalendarDate> _dayOfInstant(String iso) =>
      Option<DateTime>.fromNullable(DateTime.tryParse(iso)).map(CalendarDate.fromDateTime);
}
