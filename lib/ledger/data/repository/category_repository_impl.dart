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
  TaskEither<Failure, int> idOf(String key) => dbTask(() => _categories.idOf(key)).chainEither(
        (int? id) => Option<int>.fromNullable(id).toEither<Failure>(() => InvalidDataFailure('No "$key" category')),
      );
}
