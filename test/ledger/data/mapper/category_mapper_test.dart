import 'package:expense_tracker/core/errors/failure.dart';
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

    test('returns InvalidDataFailure for an unknown kind', () {
      expect(
        CategoryMapper.toEntity(const CategoryModel(id: 1, key: 'x', iconKey: 'x', kind: '?', sort: 0)).isLeft(),
        isTrue,
      );
    });
  });
}
