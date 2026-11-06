import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/backup_status.dart';

/// Android's own *Save to* and *Open* screens, where the user picks the place (SPEC BR-16).
abstract interface class BackupFiles {
  /// Opens *Save to* suggesting [fileName] and writes [bytes] where the user picks.
  ///
  /// Completes with [BackedUp] once written, or [None] when the user cancels. Throws when the
  /// write fails.
  Future<Option<BackedUp>> save(Uint8List bytes, String fileName);

  /// Opens *Open* showing every file, and reads the one picked.
  ///
  /// Completes with its bytes, or [None] when the user cancels. Throws when it can't be read.
  Future<Option<Uint8List>> open();
}

/// [BackupFiles] through `file_picker`, which uses the Storage Access Framework on Android, so no
/// storage permission is needed and the app never touches the network.
final class FilePickerBackupFiles implements BackupFiles {
  const FilePickerBackupFiles();

  static const String _mimeType = 'application/json';

  @override
  Future<Option<BackedUp>> save(Uint8List bytes, String fileName) async {
    final Uri? saved = await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: _mimeType);
    return Option<Uri>.fromNullable(saved).map((Uri uri) => BackedUp(fileName: fileNameOf(uri)));
  }

  @override
  Future<Option<Uint8List>> open() async {
    // why: FileType.any, not a JSON filter: some storage apps grey out a .json file under a MIME
    // filter (case study 23), so the contents are checked instead.
    final List<PlatformFile> picked = await FilePicker.pickFiles();
    if (picked.isEmpty) {
      return const Option<Uint8List>.none();
    }
    return Option<Uint8List>.of(await picked.first.xFile.readAsBytes());
  }

  /// The file name at the end of [uri], such as `hisaab-backup-2026-11-06 (1).json`.
  ///
  /// A content URI ends in a document id like `primary:Download/hisaab-backup.json`, so the text
  /// after the last `/` or `:` is taken. [None] unless it ends in `.json`: some providers, such
  /// as Drive, give an opaque id instead of the name, which would only confuse the user.
  static Option<String> fileNameOf(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return const Option<String>.none();
    }
    final String name = Uri.decodeComponent(uri.pathSegments.last).split(RegExp('[/:]')).last;
    return name.endsWith(_extension) ? Option<String>.of(name) : const Option<String>.none();
  }

  static const String _extension = '.json';
}
