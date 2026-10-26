import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
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
          // why: limits are stored without a currency; v1 ships rupees only.
          limit: Option<int>.fromNullable(model.budgetMinor).map(Money.new),
        ),
      );
}
