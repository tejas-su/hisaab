import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../model/entry_model.dart';

/// Reads and writes `transactions` rows. Throws what sqflite throws, or [RowFailureException]
/// for an unreadable row; repositories turn both into failures.
abstract interface class EntriesLocalDataSource {
  /// Rows dated from [fromIso] to [toIso] inclusive, newest first.
  Future<List<EntryModel>> between(String fromIso, String toIso);

  /// The row with [id], or null.
  Future<EntryModel?> byId(int id);

  /// Inserts [model] (with its id when set) and returns the row id.
  Future<int> insert(EntryModel model);

  /// Updates row [id] with [model]'s columns and returns the number of rows changed.
  Future<int> update(int id, EntryModel model);

  /// Deletes row [id] and returns the number of rows removed.
  Future<int> delete(int id);

  /// The earliest `created_at` of any row, or null when there are none.
  Future<String?> firstCreatedAt();

  /// The sum of every *Saved* entry and the date of the first, or `firstDate` null with none.
  Future<({int totalMinor, String? firstDate})> savedTotal();

  /// Per saving rule id: the sum of its posted *Saved* rows (`putInMinor`) and of the *Used* rows
  /// linked to it (`usedMinor`), plus whether any *Used* row exists at all (`anyUse`).
  Future<({Map<int, int> putInMinor, Map<int, int> usedMinor, bool anyUse})> savingTotals();
}

/// [EntriesLocalDataSource] backed by the app's sqflite database.
final class SqfliteEntriesLocalDataSource implements EntriesLocalDataSource {
  const SqfliteEntriesLocalDataSource(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<List<EntryModel>> between(String fromIso, String toIso) async {
    final List<Map<String, Object?>> rows = await _db.query(
      Tables.transactions,
      where: '${TransactionColumns.date} BETWEEN ? AND ?',
      whereArgs: <Object?>[fromIso, toIso],
      orderBy: '${TransactionColumns.date} DESC, ${TransactionColumns.id} DESC',
    );
    return rows.map((Map<String, Object?> row) => requireRow(EntryModel.fromRow(row))).toList();
  }

  @override
  Future<EntryModel?> byId(int id) async {
    final List<Map<String, Object?>> rows =
        await _db.query(Tables.transactions, where: '${TransactionColumns.id} = ?', whereArgs: <Object?>[id]);
    return rows.isEmpty ? null : requireRow(EntryModel.fromRow(rows.first));
  }

  @override
  Future<int> insert(EntryModel model) => _db.insert(Tables.transactions, model.toRow());

  @override
  Future<int> update(int id, EntryModel model) => _db.update(
        Tables.transactions,
        model.toRow(),
        where: '${TransactionColumns.id} = ?',
        whereArgs: <Object?>[id],
      );

  @override
  Future<int> delete(int id) =>
      _db.delete(Tables.transactions, where: '${TransactionColumns.id} = ?', whereArgs: <Object?>[id]);

  @override
  Future<String?> firstCreatedAt() async {
    const String first = 'first';
    final List<Map<String, Object?>> rows =
        await _db.rawQuery('SELECT MIN(${TransactionColumns.createdAt}) AS $first FROM ${Tables.transactions}');
    return rows.single.stringOrNullAt(first);
  }

  @override
  Future<({int totalMinor, String? firstDate})> savedTotal() async {
    const String total = 'total';
    const String first = 'first';
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(${TransactionColumns.amountMinor}), 0) AS $total, MIN(${TransactionColumns.date}) AS $first '
      'FROM ${Tables.transactions} WHERE ${TransactionColumns.kind} = ?',
      <Object?>[EntryKindValues.saved],
    );
    return (totalMinor: rows.single.intAt(total), firstDate: rows.single.stringOrNullAt(first));
  }

  @override
  Future<({Map<int, int> putInMinor, Map<int, int> usedMinor, bool anyUse})> savingTotals() async {
    final Map<int, int> putIn = await _sumsBy(TransactionColumns.recurringId, EntryKindValues.saved);
    final Map<int, int> used = await _sumsBy(TransactionColumns.savingId, EntryKindValues.used);
    final List<Map<String, Object?>> any = await _db.rawQuery(
      'SELECT EXISTS(SELECT 1 FROM ${Tables.transactions} WHERE ${TransactionColumns.kind} = ?) AS any',
      <Object?>[EntryKindValues.used],
    );
    return (putInMinor: putIn, usedMinor: used, anyUse: any.single.intAt('any') == 1);
  }

  Future<Map<int, int>> _sumsBy(String linkColumn, String kind) async {
    const String total = 'total';
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT $linkColumn AS link, SUM(${TransactionColumns.amountMinor}) AS $total '
      'FROM ${Tables.transactions} WHERE ${TransactionColumns.kind} = ? AND $linkColumn IS NOT NULL GROUP BY $linkColumn',
      <Object?>[kind],
    );
    return <int, int>{for (final Map<String, Object?> row in rows) row.intAt('link'): row.intAt(total)};
  }
}
