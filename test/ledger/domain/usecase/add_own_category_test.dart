import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:hisaab/ledger/domain/usecase/add_own_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

void main() {
  late FakeCategoryRepository categories;
  late AddOwnCategory addOwn;
  final Map<int, String> labels = <int, String>{SeedCategoryIds.food: 'Food', SeedCategoryIds.salary: 'Money in'};

  setUp(() {
    categories = FakeCategoryRepository();
    addOwn = AddOwnCategory(categories: categories);
  });

  Future<Either<Failure, Category>> add(String name, {String iconKey = 'fuel'}) =>
      addOwn(NewCategory(name: name, iconKey: iconKey, labels: labels)).run();
  Iterable<Category> own() => categories.categories.where((Category c) => c.isOwn);

  group('AddOwnCategory (BR-11, D138)', () {
    test('adds a new category with the trimmed name and the icon given', () async {
      final Category petrol = (await add('  Petrol ')).getOrElse((Failure f) => fail(f.message));

      expect(petrol.customName, 'Petrol');
      expect(petrol.iconKey, 'fuel');
      expect(own(), <Category>[petrol]);
    });

    test('a name that matches a built-in category returns that category and adds nothing', () async {
      final Category food = (await add('food')).getOrElse((Failure f) => fail(f.message));

      expect(food.id, SeedCategoryIds.food);
      expect(own(), isEmpty);
    });

    test('a name that matches a Got category is not a match: only Spent names count', () async {
      final Category added = (await add('Money in')).getOrElse((Failure f) => fail(f.message));

      expect(added.isOwn, isTrue);
    });

    test('a name that matches one of the user\'s own returns it and adds nothing', () async {
      final Category first = (await add('Petrol')).getOrElse((Failure f) => fail(f.message));

      final Category again = (await add('PETROL')).getOrElse((Failure f) => fail(f.message));

      expect(again, first);
      expect(own(), hasLength(1));
    });

    test('a hidden category\'s name brings it back, with its old icon, instead of making a copy', () async {
      final Category gym = (await add('Gym', iconKey: 'gym')).getOrElse((Failure f) => fail(f.message));
      await categories.setHidden(gym.id, hidden: true).run();

      final Category back = (await add('gym', iconKey: 'tag')).getOrElse((Failure f) => fail(f.message));

      expect(back.id, gym.id);
      expect(back.hidden, isFalse);
      expect(back.iconKey, 'gym');
      expect(own().single.hidden, isFalse);
    });

    test('a fifth shown category is refused', () async {
      for (final String name in <String>['Petrol', 'Kids', 'Pets', 'Gym']) {
        await add(name);
      }

      expect((await add('Salon')).getLeft().toNullable(), isA<OwnCategoryLimitFailure>());
      expect(own(), hasLength(4));
    });

    test('a hidden category does not count toward the 4', () async {
      for (final String name in <String>['Petrol', 'Kids', 'Pets', 'Gym']) {
        await add(name);
      }
      await categories.setHidden(own().first.id, hidden: true).run();

      expect((await add('Salon')).isRight(), isTrue);
    });

    test('bringing back a hidden category is refused when 4 are already shown', () async {
      for (final String name in <String>['Petrol', 'Kids', 'Pets', 'Gym']) {
        await add(name);
      }
      final int petrol = own().first.id;
      await categories.setHidden(petrol, hidden: true).run();
      await add('Salon');

      expect((await add('Petrol')).getLeft().toNullable(), isA<OwnCategoryLimitFailure>());
    });

    test('an invalid name is refused before anything is read', () async {
      categories.failure = DatabaseFailure('should not be reached');
      expect((await add('   ')).getLeft().toNullable(), isA<InvalidCategoryNameFailure>());
    });

    test('returns DatabaseFailure when the read fails', () async {
      categories.failure = DatabaseFailure('locked');
      expect((await add('Petrol')).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
