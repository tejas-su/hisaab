import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/category_repository.dart';

/// Accepts "Use these limits?" with one tap: saves each category's suggested limit (SPEC BR-12).
final class ApplySuggestedLimits implements UseCase<Unit, Map<int, Money>> {
  const ApplySuggestedLimits({required this._categories});

  final CategoryRepository _categories;

  /// Saves [params], limits by category id, in one write.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure` (nothing is saved).
  @override
  TaskEither<Failure, Unit> call(Map<int, Money> params) => _categories.setLimits(params);
}
