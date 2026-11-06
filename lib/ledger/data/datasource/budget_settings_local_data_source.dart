import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';

/// Reads and writes the ledger-owned keys of the `settings` table (DECISIONS D20).
abstract interface class BudgetSettingsLocalDataSource {
  /// The stored values of [keys]; keys never set are absent from the map.
  Future<Map<String, String>> values(List<String> keys);

  /// Stores [value] under [key], replacing any value already there.
  Future<void> write(String key, String value);
}

/// [BudgetSettingsLocalDataSource] backed by the app's sqflite database.
final class SqfliteBudgetSettingsLocalDataSource implements BudgetSettingsLocalDataSource {
  const SqfliteBudgetSettingsLocalDataSource(this._database);

  final AppDatabase _database;

  @override
  Future<Map<String, String>> values(List<String> keys) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.settings,
      where: '${SettingsColumns.key} IN (${List<String>.filled(keys.length, '?').join(', ')})',
      whereArgs: keys,
    );
    return <String, String>{
      for (final Map<String, Object?> row in rows)
        ...requireRow(
          readRow(Tables.settings, () => <String, String>{row.stringAt(SettingsColumns.key): row.stringAt(SettingsColumns.value)}),
        ),
    };
  }

  @override
  Future<void> write(String key, String value) => _database.db.insert(
        Tables.settings,
        <String, Object?>{SettingsColumns.key: key, SettingsColumns.value: value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
