import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/amount_mode.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entities/entry_kind.dart';
import '../entities/occurrence.dart';
import '../entities/recurring_rule.dart';
import '../failures/ledger_failures.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';

/// How much a waiting changing or card bill [occurrence] came to (D123).
final class EnterBillAmountParams extends Equatable {
  const EnterBillAmountParams({required this.occurrence, required this.amount});

  final Occurrence occurrence;
  final Money amount;

  @override
  List<Object?> get props => <Object?>[occurrence, amount];
}

/// What [EnterBillAmount] wrote, and the rule as it was, so Undo can put both back (E-e).
final class BillAmountEntered extends Equatable {
  const BillAmountEntered({required this.entry, required this.previous});

  /// The entry, linked to the rule and dated on the occurrence.
  final Entry entry;

  /// The rule before its estimate became [entry]'s amount.
  final RecurringRule previous;

  @override
  List<Object?> get props => <Object?>[entry, previous];
}

/// Records a waiting bill's amount on its own date (D123).
///
/// A changing bill becomes *Spent*; a card bill is recorded as paid and never counted, named
/// after the card. The amount then becomes the rule's estimate for next time.
final class EnterBillAmount implements UseCase<BillAmountEntered, EnterBillAmountParams> {
  const EnterBillAmount({required this._ledger, required this._recurring});

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;

  /// Returns [Right] with what was written, or [Left] with [InvalidAmountFailure] for ₹0
  /// (nothing written) or `DatabaseFailure` when the entry can't be saved.
  @override
  TaskEither<Failure, BillAmountEntered> call(EnterBillAmountParams params) {
    if (params.amount.isZero) {
      return TaskEither<Failure, BillAmountEntered>.left(const InvalidAmountFailure('A bill amount must be more than ₹0'));
    }
    final RecurringRule rule = params.occurrence.rule;
    return _ledger
        .addForRule(_draftFor(params), recurringId: rule.id)
        .flatMap((Entry entry) => _updateEstimate(rule, params.amount).map((Unit _) => BillAmountEntered(entry: entry, previous: rule)));
  }

  static EntryDraft _draftFor(EnterBillAmountParams params) {
    final RecurringRule rule = params.occurrence.rule;
    final bool card = rule.amountMode == AmountMode.card;
    return EntryDraft(
      amount: params.amount,
      kind: card ? EntryKind.cardPaid : EntryKind.spent,
      categoryId: rule.categoryId,
      date: params.occurrence.date,
      note: card ? rule.label : null,
    );
  }

  // why: the entry is what counts; a failed estimate only means next month's prefill is older,
  // so it must not report the saved bill as failed.
  TaskEither<Failure, Unit> _updateEstimate(RecurringRule rule, Money amount) => _recurring
      .update(rule.copyWith(amount: amount))
      .map((RecurringRule _) => unit)
      .orElse((Failure _) => TaskEither<Failure, Unit>.right(unit));
}
