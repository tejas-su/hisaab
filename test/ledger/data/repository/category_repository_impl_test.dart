import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/data/datasource/categories_local_data_source.dart';
import 'package:expense_tracker/ledger/data/repository/category_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late CategoryRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = CategoryRepositoryImpl(categories: SqfliteCategoriesLocalDataSource(database));
  });

  group('CategoryRepositoryImpl', () {
    test('returns the seed list in its fixed order, Spent first (BR-11)', () async {
      final List<Category> categories = (await repository.all().run()).getOrElse((Failure f) => fail(f.message));
      expect(categories, seedCategories);
    });

    test('leaves out archived categories', () async {
      await database.db.update(Tables.categories, <String, Object?>{CategoryColumns.archived: 1},
          where: '${CategoryColumns.key} = ?', whereArgs: <Object?>['fun']);
      final List<Category> categories = (await repository.all().run()).getOrElse((Failure f) => fail(f.message));
      expect(categories.map((Category c) => c.key), isNot(contains('fun')));
    });

    test('returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.all().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
