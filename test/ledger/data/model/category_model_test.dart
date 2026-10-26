import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/data/model/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const Map<String, Object?> _row = <String, Object?>{
  CategoryColumns.id: 1,
  CategoryColumns.key: 'food',
  CategoryColumns.customName: null,
  CategoryColumns.iconKey: 'food',
  CategoryColumns.kind: 'out',
  CategoryColumns.budgetMinor: null,
  CategoryColumns.sort: 0,
  CategoryColumns.archived: 0,
};

void main() {
  group('CategoryModel.fromRow', () {
    test('reads a seeded row', () {
      expect(
        CategoryModel.fromRow(_row),
        Either<Failure, CategoryModel>.right(
          const CategoryModel(id: 1, key: 'food', iconKey: 'food', kind: 'out', sort: 0),
        ),
      );
    });

    test('keeps a rename', () {
      final CategoryModel model = CategoryModel.fromRow(<String, Object?>{..._row, CategoryColumns.customName: 'Khana'})
          .getOrElse((Failure f) => fail(f.message));
      expect(model.customName, 'Khana');
    });

    test('reads a limit (BR-12)', () {
      final CategoryModel model = CategoryModel.fromRow(<String, Object?>{..._row, CategoryColumns.budgetMinor: 1000000})
          .getOrElse((Failure f) => fail(f.message));
      expect(model.budgetMinor, 1000000);
    });

    test('returns InvalidDataFailure for a limit that is not a whole number', () {
      expect(CategoryModel.fromRow(<String, Object?>{..._row, CategoryColumns.budgetMinor: '10000'}).isLeft(), isTrue);
    });

    test('returns InvalidDataFailure for a bad sort column', () {
      expect(CategoryModel.fromRow(<String, Object?>{..._row, CategoryColumns.sort: null}).isLeft(), isTrue);
    });
  });
}
