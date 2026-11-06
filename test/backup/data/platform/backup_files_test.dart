import 'package:expense_tracker/backup/data/platform/backup_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('FilePickerBackupFiles.fileNameOf', () {
    final List<(String, Option<String>)> cases = <(String, Option<String>)>[
      (
        'content://com.android.externalstorage.documents/document/primary%3ADownload%2Fhisaab-backup-2026-11-06.json',
        const Option<String>.of('hisaab-backup-2026-11-06.json'),
      ),
      (
        'content://com.android.providers.downloads.documents/document/primary%3ADownload%2Fhisaab-backup-2026-11-06%20(1).json',
        const Option<String>.of('hisaab-backup-2026-11-06 (1).json'),
      ),
      ('file:///storage/emulated/0/Download/hisaab-backup-2026-11-06.json', const Option<String>.of('hisaab-backup-2026-11-06.json')),
      ('content://com.google.android.apps.docs.storage/document/acc%3D1%3Bdoc%3D', const Option<String>.none()),
      ('content://media', const Option<String>.none()),
    ];

    for (final (String uri, Option<String> name) in cases) {
      test('reads $name from $uri', () {
        expect(FilePickerBackupFiles.fileNameOf(Uri.parse(uri)), name);
      });
    }
  });
}
