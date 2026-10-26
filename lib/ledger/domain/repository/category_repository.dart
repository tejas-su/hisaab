import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../entities/category.dart';

/// Reads the fixed category list (SPEC BR-11) and saves their limits (BR-12).
abstract interface class CategoryRepository {
  /// Loads every category, *Spent* ones first, each kind in its fixed order.
  ///
  /// Returns [Right] with the categories, or [Left] with `DatabaseFailure`.
  TaskEither<Failure, List<Category>> all();

  /// Sets the limit of each category id in [limits] in one write; other categories keep theirs.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure` (nothing is saved).
  TaskEither<Failure, Unit> setLimits(Map<int, Money> limits);
}
