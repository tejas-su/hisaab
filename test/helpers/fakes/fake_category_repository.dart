import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/repository/category_repository.dart';
import 'package:fpdart/fpdart.dart';

import '../fixtures/ledger/categories.dart';

/// A [CategoryRepository] over an in-memory [categories] list; set [failure] to make it fail.
///
/// Adding, renaming, re-iconing and hiding change [categories] in place, as the database would.
final class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([List<Category> categories = seedCategories]) : categories = List<Category>.of(categories);

  final List<Category> categories;
  Failure? failure;

  /// Hidden categories by key, as migration 003 seeds them (D120).
  Map<String, int> hidden = <String, int>{'saved': 11, 'card_paid': 12};

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
  TaskEither<Failure, int> idOf(String key) {
    final Failure? current = failure;
    if (current != null) {
      return TaskEither<Failure, int>.left(current);
    }
    final int? id = categories.where((Category c) => c.key == key).firstOrNull?.id ?? hidden[key];
    return id == null
        ? TaskEither<Failure, int>.left(InvalidDataFailure('No "$key" category'))
        : TaskEither<Failure, int>.right(id);
  }

  /// The next id [addOwn] gives; past the hidden `saved` and `card_paid` rows.
  int nextId = 13;

  @override
  TaskEither<Failure, Category> addOwn({required String name, required String iconKey}) => _guard(() {
        final int sort = categories.where((Category c) => c.kind == EntryKind.spent).fold(-1, (int a, Category c) => c.sort > a ? c.sort : a) + 1;
        final Category added = Category(
          id: nextId,
          key: '${CategoryKeys.ownPrefix}$nextId',
          customName: name,
          iconKey: iconKey,
          kind: EntryKind.spent,
          sort: sort,
        );
        nextId++;
        categories.add(added);
        return added;
      });

  @override
  TaskEither<Failure, Unit> rename(int id, String name) =>
      _change(id, (Category c) => true, (Category c) => c.copyWith(customName: name));

  @override
  TaskEither<Failure, Unit> changeIcon(int id, String iconKey) =>
      _change(id, (Category c) => true, (Category c) => c.copyWith(iconKey: iconKey));

  @override
  TaskEither<Failure, Unit> setHidden(int id, {required bool hidden}) =>
      _change(id, (Category c) => c.isOwn, (Category c) => c.copyWith(hidden: hidden));

  TaskEither<Failure, T> _guard<T>(T Function() run) {
    final Failure? current = failure;
    return current == null ? TaskEither<Failure, T>.right(run()) : TaskEither<Failure, T>.left(current);
  }

  TaskEither<Failure, Unit> _change(int id, bool Function(Category) allowed, Category Function(Category) changed) {
    final Failure? current = failure;
    if (current != null) {
      return TaskEither<Failure, Unit>.left(current);
    }
    final int index = categories.indexWhere((Category c) => c.id == id && allowed(c));
    if (index < 0) {
      return TaskEither<Failure, Unit>.left(InvalidDataFailure('No category $id to change'));
    }
    categories[index] = changed(categories[index]);
    return TaskEither<Failure, Unit>.right(unit);
  }

  /// When set, [all] fails once this many reads have succeeded (a list that won't reload).
  int? readsBeforeFailure;
  int _reads = 0;

  @override
  TaskEither<Failure, List<Category>> all() {
    final int? allowed = readsBeforeFailure;
    if (allowed != null && _reads++ >= allowed) {
      return TaskEither<Failure, List<Category>>.left(DatabaseFailure('gone'));
    }
    final Failure? current = failure;
    return current == null
        ? TaskEither<Failure, List<Category>>.right(List<Category>.of(categories))
        : TaskEither<Failure, List<Category>>.left(current);
  }
}
