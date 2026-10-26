import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:expense_tracker/ledger/domain/repository/category_repository.dart';
import 'package:fpdart/fpdart.dart';

import '../fixtures/ledger/categories.dart';

/// A [CategoryRepository] returning [categories]; set [failure] to make it fail.
final class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([this.categories = seedCategories]);

  final List<Category> categories;
  Failure? failure;

  /// Every map passed to [setLimits], in order.
  final List<Map<int, Money>> savedLimits = <Map<int, Money>>[];

  @override
  TaskEither<Failure, Unit> setLimits(Map<int, Money> limits) {
    final Failure? current = failure;
    if (current != null) {
      return TaskEither<Failure, Unit>.left(current);
    }
    savedLimits.add(limits);
    return TaskEither<Failure, Unit>.right(unit);
  }

  @override
  TaskEither<Failure, List<Category>> all() {
    final Failure? current = failure;
    return current == null
        ? TaskEither<Failure, List<Category>>.right(categories)
        : TaskEither<Failure, List<Category>>.left(current);
  }
}
