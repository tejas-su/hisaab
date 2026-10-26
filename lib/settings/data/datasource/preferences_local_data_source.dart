import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';

/// Reads and writes the settings-owned keys of the `settings` table (DECISIONS D20).
abstract interface class PreferencesLocalDataSource {
  /// The stored value of [key], or null when it was never set.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing any earlier value.
  Future<void> write(String key, String value);

  /// Sets `onboarding_done` and deletes `onboarding_draft` in one transaction.
  Future<void> markOnboardingDone();
}

/// [PreferencesLocalDataSource] backed by the app's sqflite database.
final class SqflitePreferencesLocalDataSource implements PreferencesLocalDataSource {
  const SqflitePreferencesLocalDataSource(this._database);

  /// The stored value of [SettingKeys.onboardingDone] once onboarding is finished.
  static const String done = '1';

  final AppDatabase _database;

  @override
  Future<String?> read(String key) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.settings,
      where: '${SettingsColumns.key} = ?',
      whereArgs: <Object?>[key],
    );
    return rows.isEmpty ? null : requireRow(readRow(Tables.settings, () => rows.first.stringAt(SettingsColumns.value)));
  }

  @override
  Future<void> write(String key, String value) => _write(_database.db, key, value);

  @override
  Future<void> markOnboardingDone() => _database.db.transaction((Transaction txn) async {
        await _write(txn, SettingKeys.onboardingDone, done);
        await txn.delete(Tables.settings, where: '${SettingsColumns.key} = ?', whereArgs: <Object?>[SettingKeys.onboardingDraft]);
      });

  static Future<void> _write(DatabaseExecutor db, String key, String value) => db.insert(
        Tables.settings,
        <String, Object?>{SettingsColumns.key: key, SettingsColumns.value: value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
