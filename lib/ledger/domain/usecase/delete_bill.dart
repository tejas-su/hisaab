import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/recurring_repository.dart';

/// Deletes the bill with this rule id: it stops posting and its past entries stay (SPEC BR-9).
/// [RestoreBill] undoes it.
final class DeleteBill implements UseCase<Unit, int> {
  const DeleteBill({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with [unit], or [Left] with `RuleNotFoundFailure` or `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(int ruleId) => _recurring.setActive(ruleId, active: false);
}

