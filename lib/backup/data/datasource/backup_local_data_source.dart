import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/db/migrations/migrations.dart';

/// Rows by table name, each row as column → value.
typedef TableRows = Map<String, List<Map<String, Object?>>>;

/// Raw access to every hisaab table at once, for backup, restore and *Delete everything*
/// (SPEC BR-16). Every method throws on a database error.
abstract interface class BackupLocalDataSource {
  /// Every row of every table, without the settings that stay on this phone.
  Future<TableRows> dump();

  /// [tables] shaped for schema [version], loaded into a scratch database and migrated to the
  /// current schema. Throws when a table, column or row doesn't fit, before the real data is touched.
  Future<TableRows> upgrade(int version, TableRows tables);

  /// The rows of a fresh install.
  Future<TableRows> fresh();

  /// Replaces every row of every table with [tables] plus the [local] settings, in one transaction.
  Future<void> replace(TableRows tables, Map<String, String> local);

  /// The stored value of setting [key], or [None].
  Future<Option<String>> readSetting(String key);

  /// Stores [value] for setting [key].
  Future<void> writeSetting(String key, String value);

  /// Removes the settings [keys].
  Future<void> removeSettings(Set<String> keys);

  /// How many entries exist.
  Future<int> entryCount();

  /// How many entries were created after the instant [isoInstant].
  Future<int> entriesCreatedAfter(String isoInstant);
}

/// [BackupLocalDataSource] over the app's [AppDatabase]; [scratch] opens throwaway in-memory
/// databases for checking and migrating rows.
final class SqfliteBackupLocalDataSource implements BackupLocalDataSource {
  const SqfliteBackupLocalDataSource({required this._database, required this._scratch});

  final AppDatabase _database;
  final DatabaseFactory _scratch;

  /// Settings that describe this phone, not the user's money, so a backup never carries them.
  static const Set<String> localSettings = <String>{
    SettingKeys.lastBackup,
    SettingKeys.restoreSnapshot,
    SettingKeys.restoredAt,
  };

  @override
  Future<TableRows> dump() async {
    final TableRows all = await _dumpAll(_database.db);
    return all.map(
      (String table, List<Map<String, Object?>> rows) => MapEntry<String, List<Map<String, Object?>>>(
        table,
        table == Tables.settings ? rows.where((Map<String, Object?> row) => !localSettings.contains(row[SettingsColumns.key])).toList() : rows,
      ),
    );
  }

  @override
  Future<TableRows> upgrade(int version, TableRows tables) => _withScratch(version, (Database scratch) async {
        await _replaceRows(scratch, tables);
        await scratch.transaction((Transaction txn) => runMigrations(txn, from: version, to: AppDatabase.schemaVersion));
        return _dumpAll(scratch);
      });

  @override
  Future<TableRows> fresh() => _withScratch(AppDatabase.schemaVersion, _dumpAll);

  @override
  Future<void> replace(TableRows tables, Map<String, String> local) => _database.db.transaction((Transaction txn) async {
        // why: rows go in table by table, so a child may land before its parent; checking the
        // foreign keys at commit still refuses a backup whose rows don't join up.
        await txn.execute('PRAGMA defer_foreign_keys = ON');
        await _replaceRows(txn, tables);
        for (final MapEntry<String, String> setting in local.entries) {
          await txn.insert(Tables.settings, _settingRow(setting.key, setting.value));
        }
        // why: a deferred violation would fail the COMMIT itself, which leaves SQLite's transaction
        // open and hangs sqflite; checking here throws first, so sqflite rolls back as usual.
        if ((await txn.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
          throw StateError('backup rows do not join up');
        }
      });

  @override
  Future<Option<String>> readSetting(String key) async {
    final List<Map<String, Object?>> rows =
        await _database.db.query(Tables.settings, where: '${SettingsColumns.key} = ?', whereArgs: <Object?>[key]);
    final Object? value = rows.isEmpty ? null : rows.first[SettingsColumns.value];
    return value is String ? Option<String>.of(value) : const Option<String>.none();
  }

  @override
  Future<void> writeSetting(String key, String value) =>
      _database.db.insert(Tables.settings, _settingRow(key, value), conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> removeSettings(Set<String> keys) => _database.db.delete(
        Tables.settings,
        where: '${SettingsColumns.key} IN (${List<String>.filled(keys.length, '?').join(', ')})',
        whereArgs: keys.toList(),
      );

  @override
  Future<int> entryCount() => _count('SELECT COUNT(*) FROM ${Tables.transactions}', const <Object?>[]);

  @override
  Future<int> entriesCreatedAfter(String isoInstant) => _count(
        'SELECT COUNT(*) FROM ${Tables.transactions} WHERE ${TransactionColumns.createdAt} > ?',
        <Object?>[isoInstant],
      );

  Future<int> _count(String sql, List<Object?> arguments) async =>
      Sqflite.firstIntValue(await _database.db.rawQuery(sql, arguments)) ?? 0;

  Future<T> _withScratch<T>(int version, Future<T> Function(Database scratch) use) async {
    final Database scratch = await _scratch.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: version,
        singleInstance: false,
        onCreate: (Database db, int created) => runMigrations(db, from: 0, to: created),
      ),
    );
    try {
      return await use(scratch);
    } finally {
      await scratch.close();
    }
  }

  static Future<TableRows> _dumpAll(DatabaseExecutor db) async {
    final List<String> tables = await _tableNames(db);
    final List<List<Map<String, Object?>>> rows =
        await Future.wait(tables.map((String table) => db.query(table, orderBy: 'rowid')));
    return Map<String, List<Map<String, Object?>>>.fromIterables(tables, rows);
  }

  static Future<List<String>> _tableNames(DatabaseExecutor db) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' ORDER BY name",
    );
    return rows.map((Map<String, Object?> row) => row['name']).whereType<String>().toList();
  }

  static Future<void> _replaceRows(DatabaseExecutor db, TableRows tables) async {
    for (final String table in await _tableNames(db)) {
      await db.delete(table);
    }
    for (final MapEntry<String, List<Map<String, Object?>>> table in tables.entries) {
      for (final Map<String, Object?> row in table.value) {
        await db.insert(table.key, row);
      }
    }
  }

  static Map<String, Object?> _settingRow(String key, String value) =>
      <String, Object?>{SettingsColumns.key: key, SettingsColumns.value: value};
}
