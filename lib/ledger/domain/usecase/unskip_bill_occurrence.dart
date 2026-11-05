import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/bill_skip.dart';
import '../repository/recurring_repository.dart';

/// Undoes [SkipBillOccurrence]: the bill waits again (D123).
final class UnskipBillOccurrence implements UseCase<Unit, BillSkip> {
  const UnskipBillOccurrence({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, Unit> call(BillSkip params) => _recurring.unskip(params);
}
