import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../entities/recurring_rule.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import 'enter_bill_amount.dart';

/// Undoes [EnterBillAmount]: the bill waits again, with its old estimate (E-e, D123).
final class UndoBillAmount implements UseCase<Unit, BillAmountEntered> {
  const UndoBillAmount({required this._ledger, required this._recurring});

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;

  /// Returns [Right] with [unit], or [Left] with `EntryNotFoundFailure`, `RuleNotFoundFailure` or
  /// `DatabaseFailure`; when the delete fails the estimate is left as entered.
  @override
  TaskEither<Failure, Unit> call(BillAmountEntered params) => _ledger
      .delete(params.entry.id)
      .flatMap((Entry _) => _recurring.update(params.previous))
      .map((RecurringRule _) => unit);
}
