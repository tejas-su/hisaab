import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/entry_kind.dart';
import '../model/category_model.dart';
import 'entry_kind_mapper.dart';

/// Converts [CategoryModel] rows to [Category] entities.
abstract final class CategoryMapper {
  /// Returns [Right] with the category, or [Left] with `InvalidDataFailure` for an unknown kind.
  static Either<Failure, Category> toEntity(CategoryModel model) => EntryKindMapper.fromValue(model.kind).map(
        (EntryKind kind) => Category(
          id: model.id,
          key: model.key,
          customName: model.customName,
          iconKey: model.iconKey,
          kind: kind,
          sort: model.sort,
        ),
      );
}
