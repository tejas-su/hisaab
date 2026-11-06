import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../domain/entities/category.dart';
import '../model/category_model.dart';

/// Reads and writes `categories` rows.
abstract interface class CategoriesLocalDataSource {
  /// Every non-archived category plus the user's own hidden ones, *Spent* first, each kind in
  /// its fixed order. Archived built-in and system rows (`saved`, `card_paid`) stay out.
  Future<List<CategoryModel>> all();

  /// Inserts a *Spent* category of the user's own after every other *Spent* row, keyed
  /// `own_<n>`, and returns it.
  Future<CategoryModel> insertOwn({required String name, required String iconKey});

  /// Sets `custom_name` of category [id]; returns how many rows changed (0 or 1).
  Future<int> setName(int id, String name);

  /// Sets `icon_key` of category [id]; returns how many rows changed (0 or 1).
  Future<int> setIconKey(int id, String iconKey);

  /// Sets `archived` of category [id] when it is the user's own; returns how many rows changed.
  Future<int> setArchived(int id, {required bool archived});

  /// Sets `budget_minor` for each category id in [budgetMinorById], all in one transaction.
  Future<void> setBudgets(Map<int, int> budgetMinorById);

  /// The id of the category with [key], archived or not; null when there is none.
  Future<int?> idOf(String key);
}

/// [CategoriesLocalDataSource] backed by the app's sqflite database.
final class SqfliteCategoriesLocalDataSource implements CategoriesLocalDataSource {
  const SqfliteCategoriesLocalDataSource(this._database);

  final AppDatabase _database;

  // why: GLOB, not LIKE: '_' is a LIKE wildcard, and the prefix itself contains one.
  static const String _isOwn = "${CategoryColumns.key} GLOB '${CategoryKeys.ownPrefix}*'";

  // why: 'out' sorts after 'in', so DESC puts the Spent grid first (SPEC BR-11 order).
  @override
  Future<List<CategoryModel>> all() async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      Tables.categories,
      where: '${CategoryColumns.archived} = 0 OR $_isOwn',
      orderBy: '${CategoryColumns.kind} DESC, ${CategoryColumns.sort}',
    );
    return rows.map((Map<String, Object?> row) => requireRow(CategoryModel.fromRow(row))).toList();
  }

  // why: the key is own_<largest id + 1>. Every existing own_<n> has n no larger than its own
  // id, so the new key is unused; reading and inserting in one transaction keeps it so.
  @override
  Future<CategoryModel> insertOwn({required String name, required String iconKey}) =>
      _database.db.transaction((Transaction txn) async {
        final Map<String, Object?> last = (await txn.rawQuery(
          'SELECT COALESCE(MAX(${CategoryColumns.id}), 0) AS max_id, '
          'COALESCE(MAX(CASE WHEN ${CategoryColumns.kind} = ? THEN ${CategoryColumns.sort} END), -1) AS max_sort '
          'FROM ${Tables.categories}',
          <Object?>[EntryKindValues.spent],
        ))
            .single;
        final CategoryModel model = CategoryModel(
          id: 0,
          key: '${CategoryKeys.ownPrefix}${last.intAt('max_id') + 1}',
          customName: name,
          iconKey: iconKey,
          kind: EntryKindValues.spent,
          sort: last.intAt('max_sort') + 1,
        );
        final int id = await txn.insert(Tables.categories, <String, Object?>{
          CategoryColumns.key: model.key,
          CategoryColumns.customName: model.customName,
          CategoryColumns.iconKey: model.iconKey,
          CategoryColumns.kind: model.kind,
          CategoryColumns.sort: model.sort,
        });
        return CategoryModel(
          id: id,
          key: model.key,
          customName: name,
          iconKey: iconKey,
          kind: model.kind,
          sort: model.sort,
        );
      });

  @override
  Future<int> setName(int id, String name) => _update(id, <String, Object?>{CategoryColumns.customName: name});

  @override
  Future<int> setIconKey(int id, String iconKey) => _update(id, <String, Object?>{CategoryColumns.iconKey: iconKey});

  @override
  Future<int> setArchived(int id, {required bool archived}) =>
      _update(id, <String, Object?>{CategoryColumns.archived: archived ? 1 : 0}, onlyOwn: true);

  Future<int> _update(int id, Map<String, Object?> values, {bool onlyOwn = false}) => _database.db.update(
        Tables.categories,
        values,
        where: '${CategoryColumns.id} = ?${onlyOwn ? ' AND $_isOwn' : ''}',
        whereArgs: <Object?>[id],
      );

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
