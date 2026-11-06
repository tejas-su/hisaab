import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../ledger/ledger.dart';

/// Why a change on Settings › Categories didn't save.
enum CategoryProblem {
  /// Another category already has the name.
  nameTaken,

  /// 4 of the user's own are already shown (D138).
  full,

  /// The name is blank, too long or kept for the app (BR-11).
  invalidName,

  /// The write failed; nothing changed.
  failed,
}

/// Settings › Categories' situation (FR-SE-2).
sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => <Object?>[];
}

/// The list is loading.
final class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

/// The list couldn't load; the page offers *Try again*.
final class CategoriesFailed extends CategoriesState {
  const CategoriesFailed();
}

/// Every category, hidden ones of the user's own included, and the outcome of the last change.
final class CategoriesReady extends CategoriesState {
  const CategoriesReady(
    this.categories, {
    this.savedId = const Option<int>.none(),
    this.problem = const Option<CategoryProblem>.none(),
    this.undo = const Option<Category>.none(),
  });

  final List<Category> categories;

  /// The category the last change saved, so its sheet can close or flash.
  final Option<int> savedId;

  /// Why the last change didn't save, if it didn't.
  final Option<CategoryProblem> problem;

  /// The category just hidden, for the *Undo* snackbar.
  final Option<Category> undo;

  @override
  List<Object?> get props => <Object?>[categories, savedId, problem, undo];
}
