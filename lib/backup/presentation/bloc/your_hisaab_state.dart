import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../domain/entities/backup_file.dart';
import '../../domain/entities/backup_status.dart';

/// The *Your hisaab* group's situation (SPEC FR-SE-4).
sealed class YourHisaabState extends Equatable {
  const YourHisaabState();
}

/// The last-backup day is loading; the rows show their titles only.
final class YourHisaabLoading extends YourHisaabState {
  const YourHisaabLoading();

  @override
  List<Object?> get props => <Object?>[];
}

/// The rows can act.
///
/// [busy] names the request running. [pending] is a checked backup waiting for the restore dialog.
/// [notice] is the latest one-off message, and [noticeCount] grows with each one, so the same
/// message twice still shows twice.
final class YourHisaabReady extends YourHisaabState {
  const YourHisaabReady({
    required this.status,
    this.busy = YourHisaabBusy.none,
    this.pending = const Option<PendingRestore>.none(),
    this.notice = const Option<YourHisaabNotice>.none(),
    this.noticeCount = 0,
  });

  final BackupStatus status;
  final YourHisaabBusy busy;
  final Option<PendingRestore> pending;
  final Option<YourHisaabNotice> notice;
  final int noticeCount;

  /// A copy with [busy] changed.
  YourHisaabReady busyWith(YourHisaabBusy busy) =>
      YourHisaabReady(status: status, busy: busy, pending: pending, notice: notice, noticeCount: noticeCount);

  @override
  List<Object?> get props => <Object?>[status, busy, pending, notice, noticeCount];
}

/// The request running, which the rows and dialog show as busy.
enum YourHisaabBusy {
  none,

  /// Writing a backup file; the *Back up* row reads "Backing up…".
  backingUp,

  /// Reading and checking a picked file; the *Restore* row reads "Checking the backup…".
  checking,

  /// Replacing everything; the dialog reads "Bringing back your hisaab…".
  restoring,

  /// Putting back the data from before a restore.
  undoing,
}

/// A checked backup and how many entries it would replace, for the restore dialog (BR-16).
final class PendingRestore extends Equatable {
  const PendingRestore({required this.file, required this.entriesHere});

  final BackupFile file;
  final int entriesHere;

  @override
  List<Object?> get props => <Object?>[file, entriesHere];
}

/// A one-off message for the snackbar (copy deck 34).
sealed class YourHisaabNotice extends Equatable {
  const YourHisaabNotice();

  /// Whether the data under the app was replaced, so the rest of the app must reload.
  bool get replacedData => false;

  @override
  List<Object?> get props => <Object?>[];
}

/// A backup file was written, named [fileName] when the picker said.
final class BackedUpNotice extends YourHisaabNotice {
  const BackedUpNotice(this.fileName);

  final Option<String> fileName;

  @override
  List<Object?> get props => <Object?>[fileName];
}

/// The backup file couldn't be written where the user picked.
final class BackUpFailedNotice extends YourHisaabNotice {
  const BackUpFailedNotice();
}

/// hisaab couldn't read its own data to write the file.
final class BackUpReadFailedNotice extends YourHisaabNotice {
  const BackUpReadFailedNotice();
}

/// The picked file isn't a hisaab backup.
final class NotABackupNotice extends YourHisaabNotice {
  const NotABackupNotice();
}

/// The picked file is a hisaab backup with parts missing or broken.
final class BrokenBackupNotice extends YourHisaabNotice {
  const BrokenBackupNotice();
}

/// The picked backup comes from a newer hisaab.
final class NewerBackupNotice extends YourHisaabNotice {
  const NewerBackupNotice();
}

/// The picked file couldn't be read at all.
final class OpenFailedNotice extends YourHisaabNotice {
  const OpenFailedNotice();
}

/// The backup made on [madeOn] replaced everything.
final class RestoredNotice extends YourHisaabNotice {
  const RestoredNotice(this.madeOn);

  final CalendarDate madeOn;

  @override
  bool get replacedData => true;

  @override
  List<Object?> get props => <Object?>[madeOn];
}

/// The restore stopped part way and was rolled back.
final class RestoreFailedNotice extends YourHisaabNotice {
  const RestoreFailedNotice();
}

/// The data from before the restore is back.
final class UndoneNotice extends YourHisaabNotice {
  const UndoneNotice();

  @override
  bool get replacedData => true;
}

/// Putting back the data from before the restore failed.
final class UndoFailedNotice extends YourHisaabNotice {
  const UndoFailedNotice();
}
