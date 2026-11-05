import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../model/entry_model.dart';
import '../model/recurring_model.dart';

/// Reads `recurring` rows and runs the engine's multi-row writes, each in one transaction.
abstract interface class RecurringLocalDataSource {
  /// Every active rule.
  Future<List<RecurringModel>> activeRules();

  /// Inserts [entries] (skipping any `(recurring_id, date)` already posted or skipped) and sets each rule's
  /// `next_due` from [nextDueByRuleId], atomically. Returns how many entries were inserted.
  Future<int> post(List<EntryModel> entries, Map<int, String> nextDueByRuleId);

  /// Deletes every entry and rule, then inserts [rules] and [entries], atomically.
  Future<void> startFresh(List<RecurringModel> rules, List<EntryModel> entries);

  /// Inserts a new active [rule] and returns its id.
  Future<int> insert(RecurringModel rule);

  /// Overwrites the active rule with [rule]'s id; returns the number of rows changed (0 or 1).
  Future<int> update(RecurringModel rule);

  /// Sets rule [id]'s `active` flag; returns the number of rows changed (0 or 1).
  Future<int> setActive(int id, {required bool active});

  /// Records that rule [ruleId]'s occurrence on [dateIso] didn't go out; a repeat is ignored.
  Future<void> skip(int ruleId, String dateIso);

  /// Removes that skip, if any.
  Future<void> unskip(int ruleId, String dateIso);

  /// The skips dated [fromIso] to [toIso] inclusive, as `(recurring_id, date)` pairs.
  Future<List<({int ruleId, String date})>> skipsBetween(String fromIso, String toIso);
}

/// [RecurringLocalDataSource] backed by the app's sqflite database.
final class SqfliteRecurringLocalDataSource implements RecurringLocalDataSource {
  const SqfliteRecurringLocalDataSource(this._database);

  final AppDatabase _database;

  @override
  Future<List<RecurringModel>> activeRules() async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.recurring,
      where: '${RecurringColumns.active} = 1',
      orderBy: RecurringColumns.id,
    );
    return rows.map((Map<String, Object?> row) => requireRow(RecurringModel.fromRow(row))).toList();
  }

  // why: OR IGNORE makes a repeat or racing run harmless (SPEC BR-9, E8). It would also skip a
  // CHECK violation silently, so the repository validates every entry before calling this.
  @override
  Future<int> post(List<EntryModel> entries, Map<int, String> nextDueByRuleId) =>
      _database.db.transaction((Transaction txn) async {
        int inserted = 0;
        for (final EntryModel entry in entries) {
          if (await _isSkipped(txn, entry)) {
            continue;
          }
          final int before = await _changes(txn);
          await txn.insert(Tables.transactions, entry.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
          inserted += await _changes(txn) - before;
        }
        for (final MapEntry<int, String> rule in nextDueByRuleId.entries) {
          await txn.update(
            Tables.recurring,
            <String, Object?>{RecurringColumns.nextDue: rule.value},
            where: '${RecurringColumns.id} = ?',
            whereArgs: <Object?>[rule.key],
          );
        }
        return inserted;
      });

  @override
  Future<void> startFresh(List<RecurringModel> rules, List<EntryModel> entries) =>
      _database.db.transaction((Transaction txn) async {
        await txn.delete(Tables.transactions);
        await txn.delete(Tables.recurring);
        for (final RecurringModel rule in rules) {
          await txn.insert(Tables.recurring, rule.toRow());
        }
        for (final EntryModel entry in entries) {
          await txn.insert(Tables.transactions, entry.toRow());
        }
      });

  @override
  Future<int> insert(RecurringModel rule) => _database.db.insert(Tables.recurring, rule.toRow());

  @override
  Future<int> update(RecurringModel rule) => _database.db.update(
        Tables.recurring,
        rule.toRow(),
        where: '${RecurringColumns.id} = ? AND ${RecurringColumns.active} = 1',
        whereArgs: <Object?>[rule.id],
      );

  @override
  Future<int> setActive(int id, {required bool active}) => _database.db.update(
        Tables.recurring,
        <String, Object?>{RecurringColumns.active: active ? 1 : 0},
        where: '${RecurringColumns.id} = ?',
        whereArgs: <Object?>[id],
      );

  @override
  Future<void> skip(int ruleId, String dateIso) => _database.db.insert(
        Tables.recurringSkips,
        <String, Object?>{RecurringSkipColumns.recurringId: ruleId, RecurringSkipColumns.date: dateIso},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  @override
  Future<void> unskip(int ruleId, String dateIso) => _database.db.delete(
        Tables.recurringSkips,
        where: '${RecurringSkipColumns.recurringId} = ? AND ${RecurringSkipColumns.date} = ?',
        whereArgs: <Object?>[ruleId, dateIso],
      );

  @override
  Future<List<({int ruleId, String date})>> skipsBetween(String fromIso, String toIso) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.recurringSkips,
      where: '${RecurringSkipColumns.date} BETWEEN ? AND ?',
      whereArgs: <Object?>[fromIso, toIso],
      orderBy: '${RecurringSkipColumns.date}, ${RecurringSkipColumns.recurringId}',
    );
    return rows
        .map((Map<String, Object?> row) =>
            (ruleId: row.intAt(RecurringSkipColumns.recurringId), date: row.stringAt(RecurringSkipColumns.date)))
        .toList();
  }

  // why: a skipped occurrence of a rule switched back to fixed must not be posted (E-f, D124).
  static Future<bool> _isSkipped(Transaction txn, EntryModel entry) async {
    final List<Map<String, Object?>> rows = await txn.query(
      Tables.recurringSkips,
      where: '${RecurringSkipColumns.recurringId} = ? AND ${RecurringSkipColumns.date} = ?',
      whereArgs: <Object?>[entry.recurringId, entry.date],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // why: sqflite's insert result is unreliable after an ignored conflict, but SQLite's
  // total_changes() counts only rows actually written.
  static Future<int> _changes(Transaction txn) async {
    final List<Map<String, Object?>> rows = await txn.rawQuery('SELECT total_changes() AS n');
    return rows.single.intAt('n');
  }
}
