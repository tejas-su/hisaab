import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/category.dart';
import '../entities/cycle_summary.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entities/entry_kind.dart';
import '../entry_validator.dart';
import '../failures/ledger_failures.dart';
import '../repository/category_repository.dart';
import '../repository/ledger_repository.dart';
import 'get_cycle_summary.dart';

/// Puts a one-off amount into savings today (*Put in extra*, D120).
///
/// It is capped at what is left for the cycle, so saving can never make the cycle over.
final class PutInExtra implements UseCase<Entry, Money> {
  const PutInExtra({
    required this._getCycleSummary,
    required this._ledger,
    required this._categories,
    required this._clock,
  });

  final GetCycleSummary _getCycleSummary;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final Clock _clock;

  /// Returns [Right] with the saved entry, or [Left] with `InvalidAmountFailure` (₹0 or too many
  /// digits), [PutInTooMuchFailure] when [params] is more than is left, or `DatabaseFailure`.
  @override
  TaskEither<Failure, Entry> call(Money params) => TaskEither<Failure, Money>.fromEither(EntryValidator.validateAmount(params))
      .flatMap((Money amount) => _getCycleSummary(const NoParams()).flatMap((CycleSummary summary) => _withinLeft(amount, summary)))
      .flatMap((Money amount) => _categories.idOf(CategoryKeys.saved).flatMap((int categoryId) => _ledger.add(_draft(amount, categoryId))));

  static TaskEither<Failure, Money> _withinLeft(Money amount, CycleSummary summary) =>
      amount > summary.remaining ? TaskEither<Failure, Money>.left(const PutInTooMuchFailure()) : TaskEither<Failure, Money>.right(amount);

  EntryDraft _draft(Money amount, int categoryId) =>
      EntryDraft(amount: amount, kind: EntryKind.saved, categoryId: categoryId, date: _clock.today());
}
