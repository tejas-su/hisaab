import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/data/datasource/categories_local_data_source.dart';
import 'package:hisaab/ledger/data/repository/category_repository_impl.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
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

    test('idOf finds a hidden category (D120)', () async {
      expect(await repository.idOf('saved').run(), Either<Failure, int>.right(11));
    });

    test('idOf finds a seed', () async {
      expect(await repository.idOf('bills').run(), Either<Failure, int>.right(4));
    });

    test('idOf of an unknown key is InvalidDataFailure', () async {
      expect((await repository.idOf('gift').run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('idOf returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.idOf('saved').run()).getLeft().toNullable(), isA<DatabaseFailure>());
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

  group('CategoryRepositoryImpl, categories of the user\'s own (D138)', () {
    late AppDatabase database;
    late CategoryRepositoryImpl repository;

    setUp(() async {
      database = await openTestDatabase();
      repository = CategoryRepositoryImpl(categories: SqfliteCategoriesLocalDataSource(database));
    });

    Future<List<Category>> all() async => (await repository.all().run()).getOrElse((Failure f) => fail(f.message));
    Future<Category> addOwn(String name, String iconKey) async =>
        (await repository.addOwn(name: name, iconKey: iconKey).run()).getOrElse((Failure f) => fail(f.message));

    test('addOwn adds a Spent category after the 8 built-in ones, with a key of its own', () async {
      final Category petrol = await addOwn('Petrol', 'fuel');

      expect(petrol.customName, 'Petrol');
      expect(petrol.iconKey, 'fuel');
      expect(petrol.kind, EntryKind.spent);
      expect(petrol.isOwn, isTrue);
      expect(petrol.hidden, isFalse);
      final List<Category> spent = (await all()).where((Category c) => c.kind == EntryKind.spent).toList();
      expect(spent.last, petrol);
      expect(spent.take(8).map((Category c) => c.key), seedCategories.take(8).map((Category c) => c.key));
    });

    test('addOwn keeps the order categories were made in, and gives each a distinct key', () async {
      final Category petrol = await addOwn('Petrol', 'fuel');
      final Category kids = await addOwn('Kids', 'kids');

      expect(petrol.key, isNot(kids.key));
      expect(petrol.sort, lessThan(kids.sort));
      expect((await all()).where((Category c) => c.isOwn), <Category>[petrol, kids]);
    });

    test('the built-in categories are not the user\'s own', () async {
      expect((await all()).where((Category c) => c.isOwn), isEmpty);
    });

    test('rename gives any category a new name', () async {
      expect(await repository.rename(SeedCategoryIds.food, 'Khana').run(), Either<Failure, Unit>.right(unit));
      expect((await all()).first.customName, 'Khana');
    });

    test('changeIcon gives any category a new icon key', () async {
      expect(await repository.changeIcon(SeedCategoryIds.food, 'chai').run(), Either<Failure, Unit>.right(unit));
      expect((await all()).first.iconKey, 'chai');
    });

    test('a hidden category of the user\'s own is still listed, flagged hidden, so its entries keep their name', () async {
      final Category petrol = await addOwn('Petrol', 'fuel');

      expect(await repository.setHidden(petrol.id, hidden: true).run(), Either<Failure, Unit>.right(unit));

      final Category listed = (await all()).singleWhere((Category c) => c.id == petrol.id);
      expect(listed.hidden, isTrue);
      expect(listed.customName, 'Petrol');
    });

    test('setHidden false brings a hidden category back', () async {
      final Category petrol = await addOwn('Petrol', 'fuel');
      await repository.setHidden(petrol.id, hidden: true).run();

      await repository.setHidden(petrol.id, hidden: false).run();

      expect((await all()).singleWhere((Category c) => c.id == petrol.id).hidden, isFalse);
    });

    test('a built-in category can never be hidden', () async {
      final Either<Failure, Unit> result = await repository.setHidden(SeedCategoryIds.food, hidden: true).run();

      expect(result.getLeft().toNullable(), isA<InvalidDataFailure>());
      expect((await all()).first.hidden, isFalse);
    });

    test('the system-hidden saved and card_paid categories stay out of the list', () async {
      expect((await all()).map((Category c) => c.key), isNot(anyOf(contains('saved'), contains('card_paid'))));
    });

    for (final String operation in <String>['rename', 'changeIcon', 'setHidden']) {
      test('$operation of an unknown id is InvalidDataFailure', () async {
        final Either<Failure, Unit> result = await switch (operation) {
          'rename' => repository.rename(999, 'Ghost'),
          'changeIcon' => repository.changeIcon(999, 'tag'),
          _ => repository.setHidden(999, hidden: true),
        }
            .run();
        expect(result.getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }

    test('addOwn returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.addOwn(name: 'Petrol', iconKey: 'fuel').run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('rename returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.rename(SeedCategoryIds.food, 'Khana').run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
