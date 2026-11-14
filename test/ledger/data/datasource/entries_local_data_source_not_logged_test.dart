import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/ledger/data/datasource/entries_local_data_source.dart';
import 'package:hisaab/ledger/data/model/entry_model.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';

import '../../../helpers/test_database.dart';

/// The join that tells a *Not logged* fix from spending (BR-18, D166), against real SQLite.
void main() {
  late AppDatabase database;
  late SqfliteEntriesLocalDataSource source;

  setUp(() async {
    database = await openTestDatabase();
    source = SqfliteEntriesLocalDataSource(database);
  });

  Future<int> categoryId(String key) async {
    final List<Map<String, Object?>> rows =
        await database.db.query(Tables.categories, where: '${CategoryColumns.key} = ?', whereArgs: <Object?>[key]);
    return rows.single[CategoryColumns.id]! as int;
  }

  EntryModel entry(int categoryId, {String date = '2026-10-26', String kind = 'out'}) => EntryModel(
        amountMinor: 420000,
        currency: 'INR',
        kind: kind,
        categoryId: categoryId,
        date: date,
        createdAt: '2026-10-26T10:30:00.000',
      );

  group('EntriesLocalDataSource category key', () {
    test('a row in not_logged and one in not_logged_in carry their keys; one in food does too', () async {
      final int food = await categoryId('food');
      final int spentFix = await categoryId(CategoryKeys.notLogged);
      final int gotFix = await categoryId(CategoryKeys.notLoggedIn);
      await source.insert(entry(food));
      await source.insert(entry(spentFix));
      await source.insert(entry(gotFix, kind: 'in'));

      final List<EntryModel> rows = await source.between('2026-10-26', '2026-10-26');

      expect(rows.map((EntryModel m) => m.categoryKey), <String?>[CategoryKeys.notLoggedIn, CategoryKeys.notLogged, 'food']);
    });

    test('byId and between agree on the key', () async {
      final int fix = await categoryId(CategoryKeys.notLogged);
      final int id = await source.insert(entry(fix));

      final EntryModel? byId = await source.byId(id);
      final List<EntryModel> between = await source.between('2026-10-26', '2026-10-26');

      expect(byId?.categoryKey, CategoryKeys.notLogged);
      expect(between.single, byId);
    });

    test('the join keeps the order and rows of ordinary entries: newest date, then newest id', () async {
      final int food = await categoryId('food');
      final int a = await source.insert(entry(food, date: '2026-10-25'));
      final int b = await source.insert(entry(food));
      final int c = await source.insert(entry(food));

      final List<EntryModel> rows = await source.between('2026-10-25', '2026-10-26');

      expect(rows.map((EntryModel m) => m.id), <int>[c, b, a]);
    });

    test('the flag survives a delete then a restore with the same category id (Undo)', () async {
      final int fix = await categoryId(CategoryKeys.notLogged);
      final int id = await source.insert(entry(fix));
      final EntryModel before = (await source.byId(id))!;

      await source.delete(id);
      await source.insert(before);

      expect((await source.byId(id))?.categoryKey, CategoryKeys.notLogged);
    });

    test('a row whose category is gone is still read, with no key, never dropped', () async {
      final int food = await categoryId('food');
      final int id = await source.insert(entry(food));
      await database.db.execute('PRAGMA foreign_keys = OFF');
      await database.db.update(Tables.transactions, <String, Object?>{TransactionColumns.categoryId: 9999},
          where: '${TransactionColumns.id} = ?', whereArgs: <Object?>[id]);

      final EntryModel? model = await source.byId(id);

      expect(model, isNotNull);
      expect(model?.categoryKey, isNull);
    });

    test('the key is read-only: it is never written back', () async {
      final int fix = await categoryId(CategoryKeys.notLogged);
      final int id = await source.insert(entry(fix));
      final EntryModel model = (await source.byId(id))!;

      expect(model.toRow().containsKey(TransactionColumns.categoryKey), isFalse);
    });
  });
}
