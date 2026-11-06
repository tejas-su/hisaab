import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../domain/entities/category.dart';
import '../../domain/repository/category_repository.dart';
import '../datasource/categories_local_data_source.dart';
import '../mapper/category_mapper.dart';
import '../model/category_model.dart';

/// [CategoryRepository] over sqflite.
final class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl({required this._categories});

  final CategoriesLocalDataSource _categories;

  @override
  TaskEither<Failure, List<Category>> all() => dbTask(_categories.all)
      .chainEither((List<CategoryModel> models) => models.traverseEither(CategoryMapper.toEntity));

  @override
  TaskEither<Failure, Unit> setLimits(Map<int, Money> limits) => dbTask(
        () => _categories.setBudgets(limits.map((int id, Money limit) => MapEntry<int, int>(id, limit.amountMinor))),
      ).map((void _) => unit);

  @override
  TaskEither<Failure, Category> addOwn({required String name, required String iconKey}) =>
      dbTask(() => _categories.insertOwn(name: name, iconKey: iconKey)).chainEither(CategoryMapper.toEntity);

  @override
  TaskEither<Failure, Unit> rename(int id, String name) => _changed(id, () => _categories.setName(id, name));

  @override
  TaskEither<Failure, Unit> changeIcon(int id, String iconKey) => _changed(id, () => _categories.setIconKey(id, iconKey));

  @override
  TaskEither<Failure, Unit> setHidden(int id, {required bool hidden}) =>
      _changed(id, () => _categories.setArchived(id, archived: hidden));

  // why: an update that touched no row means the id is unknown (or, for hiding, built in).
  TaskEither<Failure, Unit> _changed(int id, Future<int> Function() write) => dbTask(write).chainEither(
        (int rows) => rows == 0
            ? Either<Failure, Unit>.left(InvalidDataFailure('No category $id to change'))
            : Either<Failure, Unit>.right(unit),
      );

  @override
  TaskEither<Failure, int> idOf(String key) => dbTask(() => _categories.idOf(key)).chainEither(
        (int? id) => Option<int>.fromNullable(id).toEither<Failure>(() => InvalidDataFailure('No "$key" category')),
      );
}
