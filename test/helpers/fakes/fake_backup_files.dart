import 'dart:typed_data';

import 'package:expense_tracker/backup/data/platform/backup_files.dart';
import 'package:expense_tracker/backup/domain/entities/backup_status.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [BackupFiles]: keeps what was saved and hands back [picked] when opened.
final class FakeBackupFiles implements BackupFiles {
  /// What the next save answers; [None] acts as a cancelled *Save to* screen.
  Option<BackedUp> saveAnswer = const Option<BackedUp>.of(BackedUp(fileName: Option<String>.of('hisaab-backup.json')));

  /// The bytes the *Open* screen gives back; [None] acts as a cancelled pick.
  Option<Uint8List> picked = const Option<Uint8List>.none();

  /// Thrown by the next save or open when set.
  Object? error;

  /// Every save, as (suggested name, bytes).
  final List<(String, Uint8List)> saved = <(String, Uint8List)>[];

  @override
  Future<Option<BackedUp>> save(Uint8List bytes, String fileName) async {
    final Object? thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    if (saveAnswer.isSome()) {
      saved.add((fileName, bytes));
    }
    return saveAnswer;
  }

  @override
  Future<Option<Uint8List>> open() async {
    final Object? thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return picked;
  }
}
