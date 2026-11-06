import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';

/// What the *Your hisaab* group shows (SPEC FR-SE-4 AC-1).
final class BackupStatus extends Equatable {
  const BackupStatus({required this.lastBackedUp, required this.undo});

  /// The day of the last backup made on this phone, if any.
  final Option<CalendarDate> lastBackedUp;

  /// The restore that can still be undone, if any (SPEC BR-16: 7 days).
  final Option<RestoreUndo> undo;

  @override
  List<Object?> get props => <Object?>[lastBackedUp, undo];
}

/// A restore whose earlier data is still kept for *Undo restore* (SPEC BR-16, E42).
final class RestoreUndo extends Equatable {
  const RestoreUndo({required this.restoredOn, required this.addedSince});

  /// The day of the restore; the undo lasts 7 days from it.
  final CalendarDate restoredOn;

  /// Entries added after the restore, which an undo would remove.
  final int addedSince;

  @override
  List<Object?> get props => <Object?>[restoredOn, addedSince];
}

/// A backup file written to the place the user picked.
final class BackedUp extends Equatable {
  const BackedUp({required this.fileName});

  /// The name Android gave the file (it may add "(1)"), when the picker says.
  final Option<String> fileName;

  @override
  List<Object?> get props => <Object?>[fileName];
}
