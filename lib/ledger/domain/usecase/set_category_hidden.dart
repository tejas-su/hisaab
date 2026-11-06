import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/category.dart';
import '../failures/ledger_failures.dart';
import '../repository/category_repository.dart';

/// Whether category [id] should be hidden.
final class CategoryVisibility extends Equatable {
  const CategoryVisibility({required this.id, required this.hidden});

  final int id;
  final bool hidden;

  @override
  List<Object?> get props => <Object?>[id, hidden];
}

/// Hides one of the user's own categories, or brings it back (FR-SE-2, D138). Its entries keep it.
final class SetCategoryHidden implements UseCase<Unit, CategoryVisibility> {
  const SetCategoryHidden({required this._categories});

  final CategoryRepository _categories;

  /// Returns [Right] with [unit], or [Left] with [OwnCategoryLimitFailure] when bringing one
  /// back while 4 are shown, `InvalidDataFailure` for an unknown or built-in id, or `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(CategoryVisibility params) => params.hidden
      ? _categories.setHidden(params.id, hidden: true)
      : _categories.all().flatMap(
          (List<Category> all) => all.where((Category c) => c.isOwn && !c.hidden).length >= OwnCategories.max
              ? TaskEither<Failure, Unit>.left(const OwnCategoryLimitFailure())
              : _categories.setHidden(params.id, hidden: false),
        );
}
