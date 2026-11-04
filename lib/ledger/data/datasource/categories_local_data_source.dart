import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../model/category_model.dart';

/// Reads `categories` rows.
abstract interface class CategoriesLocalDataSource {
  /// Every non-archived category, *Spent* first, each kind in its fixed order.
  Future<List<CategoryModel>> all();

  /// Sets `budget_minor` for each category id in [budgetMinorById], all in one transaction.
  Future<void> setBudgets(Map<int, int> budgetMinorById);

  /// The id of the category with [key], archived or not; null when there is none.
  Future<int?> idOf(String key);
}

/// [CategoriesLocalDataSource] backed by the app's sqflite database.
final class SqfliteCategoriesLocalDataSource implements CategoriesLocalDataSource {
  const SqfliteCategoriesLocalDataSource(this._database);

  final AppDatabase _database;

  // why: 'out' sorts after 'in', so DESC puts the Spent grid first (SPEC BR-11 order).
  @override
  Future<List<CategoryModel>> all() async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.categories,
      where: '${CategoryColumns.archived} = 0',
      orderBy: '${CategoryColumns.kind} DESC, ${CategoryColumns.sort}',
    );
    return rows.map((Map<String, Object?> row) => requireRow(CategoryModel.fromRow(row))).toList();
  }

  @override
  Future<void> setBudgets(Map<int, int> budgetMinorById) => _database.db.transaction((Transaction txn) async {
        for (final MapEntry<int, int> budget in budgetMinorById.entries) {
          await txn.update(
            Tables.categories,
            <String, Object?>{CategoryColumns.budgetMinor: budget.value},
            where: '${CategoryColumns.id} = ?',
            whereArgs: <Object?>[budget.key],
          );
        }
      });

  @override
  Future<int?> idOf(String key) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.categories,
      columns: <String>[CategoryColumns.id],
      where: '${CategoryColumns.key} = ?',
      whereArgs: <Object?>[key],
    );
    return rows.isEmpty ? null : rows.single.intAt(CategoryColumns.id);
  }
}
