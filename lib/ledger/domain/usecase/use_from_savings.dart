import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/category.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../entities/saving_totals.dart';
import '../entry_validator.dart';
import '../failures/ledger_failures.dart';
import '../repository/category_repository.dart';
import '../repository/ledger_repository.dart';
import '../set_aside.dart';

/// What to use from which saving.
final class UseFromSavingsParams extends Equatable {
  const UseFromSavingsParams({required this.saving, required this.amount});

  /// The saving the money was paid from.
  final RecurringRule saving;

  /// A whole-rupee amount, at least ₹1 and at most what is set aside.
  final Money amount;

  @override
  List<Object?> get props => <Object?>[saving, amount];
}

/// Records a cost paid from a saving, such as a yearly insurance bill (*Used some of it*, BR-19, D175).
///
/// The entry is a fourth kind, *Used*: it moves no number, because the money was counted when it
/// was put in. The amount is checked against what is set aside at the moment of the write, so a
/// put-in deleted behind an open sheet can't be overdrawn (E99).
final class UseFromSavings implements UseCase<Entry, UseFromSavingsParams> {
  const UseFromSavings({required this._ledger, required this._categories, required this._clock});

  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final Clock _clock;

  /// Returns [Right] with the saved entry, or [Left] with `InvalidAmountFailure` (₹0 or too many
  /// digits), [UsedTooMuchFailure] when the amount is more than the whole rupees set aside (or
  /// nothing is), or `DatabaseFailure`.
  @override
  TaskEither<Failure, Entry> call(UseFromSavingsParams params) =>
      TaskEither<Failure, Money>.fromEither(EntryValidator.validateAmount(params.amount))
          .flatMap((Money amount) => _ledger.savingTotals().flatMap((SavingTotals totals) => _withinSetAside(params, totals)))
          .flatMap(
            (Money amount) => _categories.idOf(CategoryKeys.saved).flatMap(
                  (int categoryId) =>
                      _ledger.addForSaving(_draft(params.saving, amount, categoryId), savingId: params.saving.id),
                ),
          );

  static TaskEither<Failure, Money> _withinSetAside(UseFromSavingsParams params, SavingTotals totals) {
    final ({Money putIn, Money used})? sums = totals.bySaving[params.saving.id];
    final Money whole = Money.fromMajor(SetAside.of(sums?.putIn ?? Money.zero, sums?.used ?? Money.zero).floorMajor);
    return params.amount > whole
        ? TaskEither<Failure, Money>.left(const UsedTooMuchFailure())
        : TaskEither<Failure, Money>.right(params.amount);
  }

  EntryDraft _draft(RecurringRule saving, Money amount, int categoryId) => EntryDraft(
        amount: amount,
        kind: EntryKind.used,
        categoryId: categoryId,
        date: _clock.today(),
        note: saving.label,
      );
}
