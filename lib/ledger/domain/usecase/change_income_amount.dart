import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/recurring_rule.dart';
import '../entry_validator.dart';
import '../income_amount.dart';
import '../repository/recurring_repository.dart';

/// The salary [rule] and the [monthly] income the user typed for it.
final class ChangeIncomeAmountParams extends Equatable {
  const ChangeIncomeAmountParams({required this.rule, required this.monthly});

  final RecurringRule rule;
  final Money monthly;

  @override
  List<Object?> get props => <Object?>[rule, monthly];
}

/// Changes how much money comes in from Settings (SPEC FR-SE-1, DECISIONS D137).
///
/// Only the rule's amount changes, so the change counts from the next payday: pay already
/// posted stays as it came and `next_due` doesn't move.
final class ChangeIncomeAmount implements UseCase<RecurringRule, ChangeIncomeAmountParams> {
  const ChangeIncomeAmount({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with the rule as saved (the same rule, unwritten, when the amount per pay
  /// doesn't change), or [Left] with `InvalidAmountFailure` when the month or its pay is under ₹1
  /// or past ₹99,99,99,999, `RuleNotFoundFailure`, or `DatabaseFailure`.
  @override
  TaskEither<Failure, RecurringRule> call(ChangeIncomeAmountParams params) =>
      TaskEither<Failure, Money>.fromEither(
        EntryValidator.validateAmount(params.monthly)
            .flatMap((Money monthly) => EntryValidator.validateAmount(IncomeAmount.perPay(monthly, params.rule.schedule))),
      ).flatMap(
        (Money perPay) => perPay == params.rule.amount
            ? TaskEither<Failure, RecurringRule>.right(params.rule)
            : _recurring.update(params.rule.copyWith(amount: perPay)),
      );
}
