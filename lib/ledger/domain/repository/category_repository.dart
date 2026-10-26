import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/category.dart';

/// Reads the fixed category list (SPEC BR-11).
abstract interface class CategoryRepository {
  /// Loads every category, *Spent* ones first, each kind in its fixed order.
  ///
  /// Returns [Right] with the categories, or [Left] with `DatabaseFailure`.
  TaskEither<Failure, List<Category>> all();
}
