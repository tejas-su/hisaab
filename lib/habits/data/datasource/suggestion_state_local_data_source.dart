import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../model/suggestion_state_model.dart';

/// Reads and writes `suggestion_state` rows. Every method throws on a database error, and a read
/// throws [RowFailureException] for a row it can't read.
abstract interface class SuggestionStateLocalDataSource {
  /// Every stored row, lowest category id first.
  Future<List<SuggestionStateModel>> all();

  /// The row of category [categoryId]; null when it has none.
  Future<SuggestionStateModel?> byCategory(int categoryId);

  /// Stores [model], replacing the row its category already has.
  Future<void> upsert(SuggestionStateModel model);

  /// Removes the row of category [categoryId]; returns how many rows went (0 or 1).
  Future<int> delete(int categoryId);
}

/// [SuggestionStateLocalDataSource] backed by the app's sqflite database.
final class SqfliteSuggestionStateLocalDataSource implements SuggestionStateLocalDataSource {
  /// Reads and writes through [_database].
  const SqfliteSuggestionStateLocalDataSource(this._database);

  final AppDatabase _database;

  static const String _ofCategory = '${SuggestionStateColumns.categoryId} = ?';

  @override
  Future<List<SuggestionStateModel>> all() async {
    final List<Map<String, Object?>> rows =
        await _database.db.query(Tables.suggestionState, orderBy: SuggestionStateColumns.categoryId);
    return rows.map(_model).toList();
  }

  @override
  Future<SuggestionStateModel?> byCategory(int categoryId) async {
    final List<Map<String, Object?>> rows =
        await _database.db.query(Tables.suggestionState, where: _ofCategory, whereArgs: <Object?>[categoryId]);
    return rows.map(_model).firstOrNull;
  }

  @override
  Future<void> upsert(SuggestionStateModel model) =>
      _database.db.insert(Tables.suggestionState, model.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<int> delete(int categoryId) =>
      _database.db.delete(Tables.suggestionState, where: _ofCategory, whereArgs: <Object?>[categoryId]);

  static SuggestionStateModel _model(Map<String, Object?> row) => requireRow(SuggestionStateModel.fromRow(row));
}
