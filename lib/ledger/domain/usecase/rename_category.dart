import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../category_name.dart';
import '../entities/category.dart';
import '../failures/ledger_failures.dart';
import '../repository/category_repository.dart';

/// A new name for category [id], with every category's shown name.
final class CategoryRename extends Equatable {
  const CategoryRename({required this.id, required this.name, required this.labels});

  final int id;

  /// As typed; it is trimmed and checked (BR-11).
  final String name;

  /// Each category's shown name by id; built-in names are localised, so the caller supplies them.
  final Map<int, String> labels;

  @override
  List<Object?> get props => <Object?>[id, name, labels];
}

/// Renames any category, built in or the user's own (FR-SE-2).
final class RenameCategory implements UseCase<Unit, CategoryRename> {
  const RenameCategory({required this._categories});

  final CategoryRepository _categories;

  /// Renames [CategoryRename.id] to the trimmed name.
  ///
  /// Returns [Right] with [unit], or [Left] with [InvalidCategoryNameFailure] for a bad name,
  /// [CategoryNameTakenFailure] when another category of the same kind has it (hidden ones
  /// included), `InvalidDataFailure` for an unknown id, or `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(CategoryRename params) => TaskEither<Failure, String>.fromEither(
        CategoryName.validate(params.name),
      ).flatMap(
        (String name) => _categories.all().flatMap((List<Category> all) {
          final Category? renamed = all.where((Category c) => c.id == params.id).firstOrNull;
          final List<Category> others =
              all.where((Category c) => c.id != params.id && (renamed == null || c.kind == renamed.kind)).toList();
          return CategoryName.match(name, others, params.labels).isSome()
              ? TaskEither<Failure, Unit>.left(CategoryNameTakenFailure('Another category is called "$name"'))
              : _categories.rename(params.id, name);
        }),
      );
}
