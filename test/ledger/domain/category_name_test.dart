import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/domain/category_name.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fixtures/ledger/categories.dart';

void main() {
  group('CategoryName.validate (BR-11)', () {
    const Map<String, String> accepted = <String, String>{
      'Petrol': 'Petrol',
      '  Kids  ': 'Kids',
      'P': 'P',
      'Riya school fees': 'Riya school fees',
      'चाय': 'चाय',
    };
    for (final MapEntry<String, String> name in accepted.entries) {
      test('accepts "${name.key}" as "${name.value}"', () {
        expect(CategoryName.validate(name.key), Either<Failure, String>.right(name.value));
      });
    }

    for (final String name in <String>['', '   ', 'Riya school fees!', 'Savings', 'CARD BILL', ' savings ']) {
      test('rejects "$name"', () {
        expect(CategoryName.validate(name).getLeft().toNullable(), isA<InvalidCategoryNameFailure>());
      });
    }
  });

  group('CategoryName.match', () {
    final Map<int, String> labels = <int, String>{
      for (final Category c in seedCategories) c.id: c.key == 'other_income' ? 'Other income' : '${c.key[0].toUpperCase()}${c.key.substring(1)}',
    };

    test('finds a built-in category by its shown name, ignoring case and spaces', () {
      expect(CategoryName.match(' FOOD ', seedCategories, labels).toNullable()?.key, 'food');
    });

    test('finds a renamed category by its new name, not its old one', () {
      final List<Category> renamed = <Category>[
        const Category(id: 5, key: 'fun', iconKey: 'movies', kind: EntryKind.spent, sort: 4, customName: 'Movies'),
      ];
      expect(CategoryName.match('movies', renamed, <int, String>{5: 'Movies'}).toNullable()?.id, 5);
      expect(CategoryName.match('fun', renamed, <int, String>{5: 'Movies'}), const Option<Category>.none());
    });

    test('a category missing from the labels is matched by its own name', () {
      const Category petrol = Category(id: 13, key: 'own_13', iconKey: 'fuel', kind: EntryKind.spent, sort: 8, customName: 'Petrol');
      expect(CategoryName.match('petrol', const <Category>[petrol], const <int, String>{}).toNullable(), petrol);
    });

    test('no match is none', () {
      expect(CategoryName.match('Petrol', seedCategories, labels), const Option<Category>.none());
    });
  });
}
