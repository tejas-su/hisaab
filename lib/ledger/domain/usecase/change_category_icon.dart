import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/category_repository.dart';

/// A new icon for category [id]: an app-owned key from `CategoryIcon.keys` (D138).
final class CategoryIconChange extends Equatable {
  const CategoryIconChange({required this.id, required this.iconKey});

  final int id;
  final String iconKey;

  @override
  List<Object?> get props => <Object?>[id, iconKey];
}

/// Changes any category's icon (FR-SE-2).
final class ChangeCategoryIcon implements UseCase<Unit, CategoryIconChange> {
  const ChangeCategoryIcon({required this._categories});

  final CategoryRepository _categories;

  /// Returns [Right] with [unit], or [Left] with `InvalidDataFailure` for an unknown id, or
  /// `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(CategoryIconChange params) => _categories.changeIcon(params.id, params.iconKey);
}
