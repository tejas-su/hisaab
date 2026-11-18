import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../model/nudge_state_model.dart';

/// Reads and writes `nudge_state` rows. Every method throws on a database error, and a read throws
/// [RowFailureException] for a row it can't read.
abstract interface class NudgeStateLocalDataSource {
  /// Every stored row, lowest category id first.
  Future<List<NudgeStateModel>> all();

  /// Stores [model], replacing the row its category already has.
  Future<void> upsert(NudgeStateModel model);

  /// Removes every row.
  Future<void> deleteAll();
}

/// [NudgeStateLocalDataSource] backed by the app's sqflite database.
final class SqfliteNudgeStateLocalDataSource implements NudgeStateLocalDataSource {
  /// Reads and writes through [_database].
  const SqfliteNudgeStateLocalDataSource(this._database);

  final AppDatabase _database;

  @override
  Future<List<NudgeStateModel>> all() async {
    final List<Map<String, Object?>> rows =
        await _database.db.query(Tables.nudgeState, orderBy: NudgeStateColumns.categoryId);
    return rows.map((Map<String, Object?> row) => requireRow(NudgeStateModel.fromRow(row))).toList();
  }

  @override
  Future<void> upsert(NudgeStateModel model) =>
      _database.db.insert(Tables.nudgeState, model.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> deleteAll() => _database.db.delete(Tables.nudgeState);
}
