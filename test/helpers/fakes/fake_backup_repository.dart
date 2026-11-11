import 'dart:async';

import 'package:hisaab/backup/domain/entities/backup_file.dart';
import 'package:hisaab/backup/domain/entities/backup_status.dart';
import 'package:hisaab/backup/domain/repository/backup_repository.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:fpdart/fpdart.dart';

/// A tiny backup file made on 12 Oct with 214 entries, for blocs and widgets.
const BackupFile fakeBackupFile = BackupFile(
  schemaVersion: 3,
  madeOn: CalendarDate(2026, 10, 12),
  tables: <String, List<Map<String, Object?>>>{},
  entryCount: 214,
);

/// A configurable [BackupRepository] that records what it was asked to do.
final class FakeBackupRepository implements BackupRepository {
  /// What [status] answers.
  Either<Failure, BackupStatus> statusAnswer = Either<Failure, BackupStatus>.right(
    const 
    BackupStatus(lastBackedUp: Option<CalendarDate>.none(), undo: Option<RestoreUndo>.none()),
  );

  /// What [backUp] answers.
  Either<Failure, Option<BackedUp>> backUpAnswer = Either<Failure, Option<BackedUp>>.right(
    const 
    Option<BackedUp>.of(BackedUp(fileName: Option<String>.of('hisaab-backup-2026-11-06.json'))),
  );

  /// What [pick] answers.
  Either<Failure, Option<BackupFile>> pickAnswer =
      Either<Failure, Option<BackupFile>>.right(const Option<BackupFile>.of(fakeBackupFile));

  /// What [entryCount] answers.
  Either<Failure, int> entryCountAnswer = Either<Failure, int>.right(37);

  /// What [restore], [undoRestore] and [wipe] answer.
  Either<Failure, Unit> writeAnswer = Either<Failure, Unit>.right(unit);

  /// When set, [backUp] and [restore] wait for it, so a test can overlap a second request.
  Completer<void>? gate;

  int backUps = 0;
  int undos = 0;
  int wipes = 0;
  final List<(BackupFile, bool)> restores = <(BackupFile, bool)>[];

  @override
  TaskEither<Failure, BackupStatus> status(CalendarDate today) => TaskEither<Failure, BackupStatus>.fromEither(statusAnswer);

  @override
  TaskEither<Failure, Option<BackedUp>> backUp(CalendarDate today) => TaskEither<Failure, Option<BackedUp>>(() async {
        backUps++;
        await gate?.future;
        return backUpAnswer;
      });

  @override
  TaskEither<Failure, Option<BackupFile>> pick() => TaskEither<Failure, Option<BackupFile>>.fromEither(pickAnswer);

  @override
  TaskEither<Failure, int> entryCount() => TaskEither<Failure, int>.fromEither(entryCountAnswer);

  @override
  TaskEither<Failure, Unit> restore(BackupFile file, {required DateTime at, required bool keepUndo}) =>
      TaskEither<Failure, Unit>(() async {
        restores.add((file, keepUndo));
        await gate?.future;
        return writeAnswer;
      });

  @override
  TaskEither<Failure, Unit> undoRestore() => TaskEither<Failure, Unit>(() async {
        undos++;
        return writeAnswer;
      });

  @override
  TaskEither<Failure, Unit> wipe() => TaskEither<Failure, Unit>(() async {
        wipes++;
        await gate?.future;
        return writeAnswer;
      });
}
