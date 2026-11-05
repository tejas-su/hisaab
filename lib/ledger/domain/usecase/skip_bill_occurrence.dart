import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/bill_skip.dart';
import '../entities/occurrence.dart';
import '../repository/recurring_repository.dart';

/// "Didn't go out this month": the waiting [Occurrence] needs no amount (D123).
final class SkipBillOccurrence implements UseCase<BillSkip, Occurrence> {
  const SkipBillOccurrence({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with the skip, for Undo, or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, BillSkip> call(Occurrence params) {
    final BillSkip skip = BillSkip(ruleId: params.rule.id, date: params.date);
    return _recurring.skip(skip).map((Unit _) => skip);
  }
}
