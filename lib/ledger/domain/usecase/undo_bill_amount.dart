import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../entities/recurring_rule.dart';
import '../failures/ledger_failures.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import 'enter_bill_amount.dart';

/// Undoes [EnterBillAmount]: the bill waits again, with its old estimate (E-e, D123).
final class UndoBillAmount implements UseCase<Unit, BillAmountEntered> {
  const UndoBillAmount({required this._ledger, required this._recurring});

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;

  /// Returns [Right] with [unit], or [Left] with `RuleNotFoundFailure` or `DatabaseFailure`;
  /// when the delete fails the estimate is left as entered. An entry already swiped away still
  /// gets its old estimate back.
  @override
  TaskEither<Failure, Unit> call(BillAmountEntered params) => _ledger
      .delete(params.entry.id)
      .map((Entry _) => unit)
      .orElse(_alreadyGone)
      .flatMap((Unit _) => _recurring.update(params.previous))
      .map((RecurringRule _) => unit);

  // why: the entry is gone either way; only the estimate is left to put back.
  static TaskEither<Failure, Unit> _alreadyGone(Failure failure) => failure is EntryNotFoundFailure
      ? TaskEither<Failure, Unit>.right(unit)
      : TaskEither<Failure, Unit>.left(failure);
}
