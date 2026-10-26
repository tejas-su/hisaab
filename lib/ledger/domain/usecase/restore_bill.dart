import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/recurring_repository.dart';

/// Brings back a bill just deleted with `DeleteBill` (Undo).
final class RestoreBill implements UseCase<Unit, int> {
  const RestoreBill({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with [unit], or [Left] with `RuleNotFoundFailure` or `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(int ruleId) => _recurring.setActive(ruleId, active: true);
}
