import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../category_name.dart';
import '../entities/category.dart';
import '../entities/entry_kind.dart';
import '../failures/ledger_failures.dart';
import '../repository/category_repository.dart';

/// The name and icon for a new category of the user's own, with every category's shown name.
final class NewCategory extends Equatable {
  const NewCategory({required this.name, required this.iconKey, required this.labels});

  /// As typed; it is trimmed and checked (BR-11).
  final String name;

  /// An app-owned key from `CategoryIcon.keys`.
  final String iconKey;

  /// Each category's shown name by id; built-in names are localised, so the caller supplies them.
  final Map<int, String> labels;

  @override
  List<Object?> get props => <Object?>[name, iconKey, labels];
}

/// Makes a *Spent* category of the user's own, or finds the one the name already belongs to
/// (SPEC BR-11, FR-AD-9, D138).
final class AddOwnCategory implements UseCase<Category, NewCategory> {
  const AddOwnCategory({required this._categories});

  final CategoryRepository _categories;

  /// Returns the category to file under [params]'s name: an existing *Spent* category with that
  /// name; a hidden one of the user's own, brought back with its old icon; or a new one.
  ///
  /// Returns [Right] with it, or [Left] with [InvalidCategoryNameFailure] for a bad name,
  /// [OwnCategoryLimitFailure] when 4 of the user's own are already shown, or `DatabaseFailure`.
  @override
  TaskEither<Failure, Category> call(NewCategory params) => TaskEither<Failure, String>.fromEither(
        CategoryName.validate(params.name),
      ).flatMap(
        (String name) => _categories.all().flatMap(
              (List<Category> all) => CategoryName.match(
                name,
                all.where((Category c) => c.kind == EntryKind.spent).toList(),
                params.labels,
              ).match(
                () => _whenRoom(all, () => _categories.addOwn(name: name, iconKey: params.iconKey)),
                (Category found) => found.hidden
                    ? _whenRoom(all, () => _categories.setHidden(found.id, hidden: false).map((Unit _) => found.copyWith(hidden: false)))
                    : TaskEither<Failure, Category>.right(found),
              ),
            ),
      );

  static TaskEither<Failure, Category> _whenRoom(List<Category> all, TaskEither<Failure, Category> Function() add) =>
      all.where((Category c) => c.isOwn && !c.hidden).length >= OwnCategories.max
          ? TaskEither<Failure, Category>.left(const OwnCategoryLimitFailure())
          : add();
}
