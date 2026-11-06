import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:expense_tracker/ledger/domain/usecase/change_category_icon.dart';
import 'package:expense_tracker/ledger/domain/usecase/rename_category.dart';
import 'package:expense_tracker/ledger/domain/usecase/set_category_hidden.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

void main() {
  late FakeCategoryRepository categories;
  final Map<int, String> labels = <int, String>{SeedCategoryIds.food: 'Food', SeedCategoryIds.travel: 'Travel'};

  setUp(() => categories = FakeCategoryRepository());

  Category byId(int id) => categories.categories.singleWhere((Category c) => c.id == id);
  Future<Category> addOwn(String name) async =>
      (await categories.addOwn(name: name, iconKey: 'tag').run()).getOrElse((Failure f) => fail(f.message));

  group('RenameCategory (FR-SE-2)', () {
    Future<Either<Failure, Unit>> rename(int id, String name) =>
        RenameCategory(categories: categories)(CategoryRename(id: id, name: name, labels: labels)).run();

    test('renames a built-in category, trimmed', () async {
      expect(await rename(SeedCategoryIds.food, ' Khana '), Either<Failure, Unit>.right(unit));
      expect(byId(SeedCategoryIds.food).customName, 'Khana');
    });

    test('a category may keep its own name with different case', () async {
      expect(await rename(SeedCategoryIds.food, 'FOOD'), Either<Failure, Unit>.right(unit));
    });

    test('a name another category already has is refused', () async {
      expect((await rename(SeedCategoryIds.food, 'travel')).getLeft().toNullable(), isA<CategoryNameTakenFailure>());
      expect(byId(SeedCategoryIds.food).customName, isNull);
    });

    test('a hidden category\'s name is taken too', () async {
      final Category gym = await addOwn('Gym');
      await categories.setHidden(gym.id, hidden: true).run();
      expect((await rename(SeedCategoryIds.food, 'gym')).getLeft().toNullable(), isA<CategoryNameTakenFailure>());
    });

    test('an invalid name is refused', () async {
      expect((await rename(SeedCategoryIds.food, 'Savings')).getLeft().toNullable(), isA<InvalidCategoryNameFailure>());
    });

    test('returns DatabaseFailure when the read fails', () async {
      categories.failure = DatabaseFailure('locked');
      expect((await rename(SeedCategoryIds.food, 'Khana')).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('ChangeCategoryIcon (FR-SE-2)', () {
    test('sets the icon key', () async {
      final Either<Failure, Unit> result =
          await ChangeCategoryIcon(categories: categories)(const CategoryIconChange(id: SeedCategoryIds.food, iconKey: 'chai')).run();
      expect(result, Either<Failure, Unit>.right(unit));
      expect(byId(SeedCategoryIds.food).iconKey, 'chai');
    });

    test('returns the repository failure', () async {
      categories.failure = DatabaseFailure('locked');
      final Either<Failure, Unit> result =
          await ChangeCategoryIcon(categories: categories)(const CategoryIconChange(id: SeedCategoryIds.food, iconKey: 'chai')).run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('SetCategoryHidden (FR-SE-2, D138)', () {
    Future<Either<Failure, Unit>> setHidden(int id, {required bool hidden}) =>
        SetCategoryHidden(categories: categories)(CategoryVisibility(id: id, hidden: hidden)).run();

    test('hides one of the user\'s own', () async {
      final Category petrol = await addOwn('Petrol');
      expect(await setHidden(petrol.id, hidden: true), Either<Failure, Unit>.right(unit));
      expect(byId(petrol.id).hidden, isTrue);
    });

    test('brings it back', () async {
      final Category petrol = await addOwn('Petrol');
      await setHidden(petrol.id, hidden: true);
      expect(await setHidden(petrol.id, hidden: false), Either<Failure, Unit>.right(unit));
      expect(byId(petrol.id).hidden, isFalse);
    });

    test('bringing one back is refused when 4 are already shown', () async {
      final Category petrol = await addOwn('Petrol');
      await setHidden(petrol.id, hidden: true);
      for (final String name in <String>['Kids', 'Pets', 'Gym', 'Salon']) {
        await addOwn(name);
      }
      expect((await setHidden(petrol.id, hidden: false)).getLeft().toNullable(), isA<OwnCategoryLimitFailure>());
    });

    test('a built-in category can\'t be hidden', () async {
      expect((await setHidden(SeedCategoryIds.food, hidden: true)).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('returns DatabaseFailure when the read fails', () async {
      categories.failure = DatabaseFailure('locked');
      expect((await setHidden(1, hidden: false)).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
