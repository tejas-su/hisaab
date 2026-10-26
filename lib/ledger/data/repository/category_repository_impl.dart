import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
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
}
