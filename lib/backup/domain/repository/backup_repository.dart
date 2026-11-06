import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../entities/backup_file.dart';
import '../entities/backup_status.dart';

/// Backing up, restoring and wiping all of hisaab's data (SPEC BR-16, FR-SE-4).
abstract interface class BackupRepository {
  /// The last-backup day and any restore that can still be undone on [today]; an undo older than
  /// 7 days is dropped here.
  TaskEither<Failure, BackupStatus> status(CalendarDate today);

  /// Writes everything to a file the user places through the system *Save to* screen, and
  /// remembers [today] as the last backup. [None] when the user cancels.
  TaskEither<Failure, Option<BackedUp>> backUp(CalendarDate today);

  /// Lets the user pick a file, then reads and checks it, bringing an older one up to date. [None]
  /// when the user cancels. Changes nothing.
  TaskEither<Failure, Option<BackupFile>> pick();

  /// How many entries are on this phone now.
  TaskEither<Failure, int> entryCount();

  /// Replaces everything with [file] in one transaction, keeping the earlier data for *Undo
  /// restore* when [keepUndo], stamped [at].
  TaskEither<Failure, Unit> restore(BackupFile file, {required DateTime at, required bool keepUndo});

  /// Puts back the data from before the last restore and forgets it.
  TaskEither<Failure, Unit> undoRestore();

  /// Clears everything back to a fresh install in one transaction, keeping no copy.
  TaskEither<Failure, Unit> wipe();
}
