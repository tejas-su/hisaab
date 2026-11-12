import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_row.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/habits/data/datasource/suggestion_state_local_data_source.dart';
import 'package:hisaab/habits/data/model/suggestion_state_model.dart';
import 'package:hisaab/ledger/data/datasource/categories_local_data_source.dart';
import 'package:hisaab/ledger/data/model/category_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_database.dart';

// why: the foreign key is on, so every row names a seeded category (ids 1–10).
const SuggestionStateModel _food = SuggestionStateModel(
  categoryId: 1,
  quietOn: '2026-10-26',
  restUntil: '2026-11-25',
  forgottenAt: '2026-10-26T10:05:00.000',
);
const SuggestionStateModel _travel = SuggestionStateModel(categoryId: 2, quietOn: '2026-10-20');

void main() {
  late AppDatabase database;
  late SqfliteSuggestionStateLocalDataSource source;

  setUp(() async {
    database = await openTestDatabase();
    source = SqfliteSuggestionStateLocalDataSource(database);
  });

  group('SqfliteSuggestionStateLocalDataSource', () {
    test('all of an empty table is empty', () async {
      expect(await source.all(), isEmpty);
    });

    test('upsert then all returns the row', () async {
      await source.upsert(_food);

      expect(await source.all(), <SuggestionStateModel>[_food]);
    });

    test('all returns every category, lowest id first', () async {
      await source.upsert(_travel);
      await source.upsert(_food);

      expect(await source.all(), <SuggestionStateModel>[_food, _travel]);
    });

    test('upsert replaces', () async {
      await source.upsert(_food);

      await source.upsert(const SuggestionStateModel(categoryId: 1, quietOn: '2026-10-27'));

      expect(await source.all(), <SuggestionStateModel>[const SuggestionStateModel(categoryId: 1, quietOn: '2026-10-27')]);
    });

    test('byCategory returns that category\'s row', () async {
      await source.upsert(_food);
      await source.upsert(_travel);

      expect(await source.byCategory(2), _travel);
    });

    test('byCategory of an unknown id is null', () async {
      await source.upsert(_food);

      expect(await source.byCategory(2), isNull);
    });

    test('delete removes it and returns 1', () async {
      await source.upsert(_food);
      await source.upsert(_travel);

      expect(await source.delete(1), 1);
      expect(await source.all(), <SuggestionStateModel>[_travel]);
    });

    test('delete of an unknown id returns 0', () async {
      expect(await source.delete(1), 0);
    });

    test('upsert for a category that does not exist throws', () async {
      await expectLater(source.upsert(const SuggestionStateModel(categoryId: 999)), throwsA(isA<DatabaseException>()));
    });

    test('an unreadable row throws RowFailureException', () async {
      // why: a TEXT column turns an int into text, so only a BLOB reads back as the wrong type.
      await database.db.rawInsert(
        "INSERT INTO ${Tables.suggestionState} (${SuggestionStateColumns.categoryId}, ${SuggestionStateColumns.quietOn}) VALUES (1, X'00')",
      );

      await expectLater(source.all(), throwsA(isA<RowFailureException>()));
      await expectLater(source.byCategory(1), throwsA(isA<RowFailureException>()));
    });

    test('hiding a category and bringing it back keeps its row (E69)', () async {
      final SqfliteCategoriesLocalDataSource categories = SqfliteCategoriesLocalDataSource(database);
      final CategoryModel chai = await categories.insertOwn(name: 'Chai', iconKey: 'chai');
      final SuggestionStateModel state = SuggestionStateModel(categoryId: chai.id, quietOn: '2026-10-26', restUntil: '2026-11-25');
      await source.upsert(state);

      expect(await categories.setArchived(chai.id, archived: true), 1);
      expect(await source.byCategory(chai.id), state);
      expect(await categories.setArchived(chai.id, archived: false), 1);

      expect(await source.byCategory(chai.id), state);
    });

    test('renaming a category and changing its icon keep its row (E69)', () async {
      final SqfliteCategoriesLocalDataSource categories = SqfliteCategoriesLocalDataSource(database);
      await source.upsert(_food);

      await categories.setName(1, 'Khana');
      await categories.setIconKey(1, 'chai');
      await categories.setBudgets(<int, int>{1: 500000});

      expect(await source.byCategory(1), _food);
    });
  });
}
