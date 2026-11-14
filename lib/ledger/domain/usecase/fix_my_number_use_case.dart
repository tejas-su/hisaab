import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/category.dart';
import '../entities/cycle_summary.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entities/entry_kind.dart';
import '../entities/fix_preview.dart';
import '../entry_validator.dart';
import '../failures/ledger_failures.dart';
import '../fix_my_number.dart';
import '../repository/budget_settings_repository.dart';
import '../repository/category_repository.dart';
import '../repository/ledger_repository.dart';
import 'get_cycle_summary.dart';

/// What the user typed and the gap they were shown (BR-18 *Stale write*).
final class FixParams extends Equatable {
  const FixParams({required this.typedRupees, required this.seenGapRupees});

  /// `T`: the whole-rupee figure the user typed, from ₹0.
  final int typedRupees;

  /// The signed whole rupees the preview showed (`FixMyNumber.signedRupees`); the write refuses if
  /// they differ now. Rupees, not paise, so a sub-rupee drift never refuses a save (D191).
  final int seenGapRupees;

  @override
  List<Object?> get props => <Object?>[typedRupees, seenGapRupees];
}

/// Posts the one *Not logged* entry that makes hisaab's figure match what the user holds (BR-18).
///
/// The write **recomputes `H` and the gap itself** and refuses a stale one, so a midnight or a bill
/// posted behind the open sheet can't save an amount the user never saw (E84).
final class FixMyNumberUseCase implements UseCase<Entry, FixParams> {
  const FixMyNumberUseCase({
    required this._summary,
    required this._ledger,
    required this._categories,
    required this._settings,
    required this._clock,
  });

  /// The note every fix carries; also its CSV value (BR-15).
  static const String entryNote = 'Not logged';

  final GetCycleSummary _summary;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final BudgetSettingsRepository _settings;
  final Clock _clock;

  /// Returns [Right] with the saved entry, or [Left] with [FixStaleFailure] when the gap is no
  /// longer the one shown (nothing written), [FixNothingToFixFailure] when the figures now match,
  /// `InvalidAmountFailure` from the validator, or `DatabaseFailure`.
  ///
  /// A failure to remember that the install line is used up is swallowed: the fix stands.
  @override
  TaskEither<Failure, Entry> call(FixParams params) =>
      _summary(const NoParams()).flatMap((CycleSummary summary) => _post(summary, params)).flatMap(_markInstallLineSeen);

  TaskEither<Failure, Entry> _post(CycleSummary summary, FixParams params) {
    if (FixMyNumber.signedRupees(summary, params.typedRupees) != params.seenGapRupees) {
      return TaskEither<Failure, Entry>.left(const FixStaleFailure());
    }
    return FixMyNumber.post(summary, params.typedRupees).match(
      () => TaskEither<Failure, Entry>.left(const FixNothingToFixFailure()),
      (FixPost post) => _categories
          .idOf(post.kind == EntryKind.spent ? CategoryKeys.notLogged : CategoryKeys.notLoggedIn)
          .flatMap((int categoryId) => _save(post, categoryId)),
    );
  }

  TaskEither<Failure, Entry> _save(FixPost post, int categoryId) => TaskEither<Failure, EntryDraft>.fromEither(
        EntryValidator.validate(
          EntryDraft(amount: post.amount, kind: post.kind, categoryId: categoryId, date: _clock.today(), note: entryNote),
          today: _clock.today(),
        ),
      ).flatMap(_ledger.add);

  // why: any fix uses up the one-time install line (C11); the flag is a convenience, so a failed
  // write must not turn a saved fix into an error.
  TaskEither<Failure, Entry> _markInstallLineSeen(Entry entry) => _settings
      .markInstallLineSeen()
      .orElse((Failure _) => TaskEither<Failure, Unit>.right(unit))
      .map((Unit _) => entry);
}
