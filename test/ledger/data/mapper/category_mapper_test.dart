import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/data/mapper/category_mapper.dart';
import 'package:expense_tracker/ledger/data/model/category_model.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('CategoryMapper', () {
    test('maps a row to a category', () {
      expect(
        CategoryMapper.toEntity(const CategoryModel(id: 9, key: 'salary', iconKey: 'salary', kind: 'in', sort: 0, customName: 'Pay')),
        Either<Failure, Category>.right(
          const Category(id: 9, key: 'salary', iconKey: 'salary', kind: EntryKind.got, sort: 0, customName: 'Pay'),
        ),
      );
    });

    test('a stored limit becomes rupees (BR-12)', () {
      final Category category = CategoryMapper.toEntity(
        const CategoryModel(id: 1, key: 'food', iconKey: 'food', kind: 'out', sort: 0, budgetMinor: 1000000),
      ).getOrElse((Failure f) => fail(f.message));
      expect(category.limit, Option<Money>.of(Money.fromMajor(10000)));
    });

    test('no stored limit is no limit', () {
      final Category category = CategoryMapper.toEntity(
        const CategoryModel(id: 1, key: 'food', iconKey: 'food', kind: 'out', sort: 0),
      ).getOrElse((Failure f) => fail(f.message));
      expect(category.limit, const Option<Money>.none());
    });

    test('returns InvalidDataFailure for an unknown kind', () {
      expect(
        CategoryMapper.toEntity(const CategoryModel(id: 1, key: 'x', iconKey: 'x', kind: '?', sort: 0)).isLeft(),
        isTrue,
      );
    });
  });
}
