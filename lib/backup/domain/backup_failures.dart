import '../../core/errors/failure.dart';

/// The picked file isn't a hisaab backup at all, or its owner never finished onboarding (SPEC BR-16).
final class NotABackupFailure extends Failure {
  const NotABackupFailure(super.message);
}

/// The file says it is a hisaab backup but parts are missing or can't be loaded (SPEC E14).
final class BrokenBackupFailure extends Failure {
  const BrokenBackupFailure(super.message);
}

/// The backup was made by a newer hisaab than this one; nothing is changed (SPEC E14).
final class NewerBackupFailure extends Failure {
  const NewerBackupFailure(super.message);
}

/// The picked file couldn't be read at all (SPEC E37).
final class BackupOpenFailure extends Failure {
  const BackupOpenFailure(super.message);
}

/// Writing the backup file to the picked place failed (SPEC E36).
final class BackupWriteFailure extends Failure {
  const BackupWriteFailure(super.message);
}
