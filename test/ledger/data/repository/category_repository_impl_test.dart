import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/data/datasource/categories_local_data_source.dart';
import 'package:expense_tracker/ledger/data/repository/category_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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

    Future<Map<String, Option<Money>>> limitsByKey() async =>
        <String, Option<Money>>{
          for (final Category c in (await repository.all().run()).getOrElse((Failure f) => fail(f.message))) c.key: c.limit,
        };

    test('setLimits saves every limit given and leaves the rest off (BR-12)', () async {
      final Either<Failure, Unit> saved = await repository
          .setLimits(<int, Money>{SeedCategoryIds.food: Money.fromMajor(10000), SeedCategoryIds.travel: Money.fromMajor(4500)})
          .run();
      expect(saved, Either<Failure, Unit>.right(unit));
      final Map<String, Option<Money>> limits = await limitsByKey();
      expect(limits['food'], Option<Money>.of(Money.fromMajor(10000)));
      expect(limits['travel'], Option<Money>.of(Money.fromMajor(4500)));
      expect(limits['shopping'], const Option<Money>.none());
    });

    test('setLimits replaces an earlier limit', () async {
      await repository.setLimits(<int, Money>{SeedCategoryIds.food: Money.fromMajor(10000)}).run();
      await repository.setLimits(<int, Money>{SeedCategoryIds.food: Money.fromMajor(9500)}).run();
      expect((await limitsByKey())['food'], Option<Money>.of(Money.fromMajor(9500)));
    });

    test('setLimits with nothing to save changes nothing', () async {
      expect(await repository.setLimits(const <int, Money>{}).run(), Either<Failure, Unit>.right(unit));
      expect((await limitsByKey()).values, everyElement(const Option<Money>.none()));
    });

    test('setLimits returns DatabaseFailure when the database is closed', () async {
      await database.close();
      final Either<Failure, Unit> saved =
          await repository.setLimits(<int, Money>{SeedCategoryIds.food: Money.fromMajor(500)}).run();
      expect(saved.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
