import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../entities/category.dart';

/// Reads and changes categories (SPEC BR-11, D138) and saves their limits (BR-12).
abstract interface class CategoryRepository {
  /// Loads every category, *Spent* ones first, each kind in its fixed order.
  ///
  /// Returns [Right] with the categories, or [Left] with `DatabaseFailure`.
  TaskEither<Failure, List<Category>> all();

  /// Sets the limit of each category id in [limits] in one write; other categories keep theirs.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure` (nothing is saved).
  TaskEither<Failure, Unit> setLimits(Map<int, Money> limits);

  /// The id of the category with [key], including hidden ones such as `saved` (D120).
  ///
  /// Returns [Right] with the id, or [Left] with `InvalidDataFailure` when no category has
  /// [key], or `DatabaseFailure` when the read fails.
  TaskEither<Failure, int> idOf(String key);

  /// Adds a *Spent* category of the user's own, named [name] with [iconKey], after every other
  /// *Spent* category. Callers check the name and the count of 4 first (D138).
  ///
  /// Returns [Right] with the new category, or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Category> addOwn({required String name, required String iconKey});

  /// Gives category [id] the name [name]; any category can be renamed (FR-SE-2).
  ///
  /// Returns [Right] with [unit], or [Left] with `InvalidDataFailure` when no category has
  /// [id], or `DatabaseFailure` when the write fails.
  TaskEither<Failure, Unit> rename(int id, String name);

  /// Gives category [id] the icon [iconKey], an app-owned key (D138).
  ///
  /// Returns [Right] with [unit], or [Left] with `InvalidDataFailure` when no category has
  /// [id], or `DatabaseFailure` when the write fails.
  TaskEither<Failure, Unit> changeIcon(int id, String iconKey);

  /// Hides category [id], or brings it back when [hidden] is false. Only the user's own can be
  /// hidden; its entries keep it (D138).
  ///
  /// Returns [Right] with [unit], or [Left] with `InvalidDataFailure` when [id] is unknown or
  /// built in, or `DatabaseFailure` when the write fails.
  TaskEither<Failure, Unit> setHidden(int id, {required bool hidden});
}
