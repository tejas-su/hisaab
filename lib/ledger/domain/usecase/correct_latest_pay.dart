import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../repository/ledger_repository.dart';

/// The posted [pay] to change and its new [amount].
final class CorrectLatestPayParams extends Equatable {
  const CorrectLatestPayParams({required this.pay, required this.amount});

  final Entry pay;
  final Money amount;

  @override
  List<Object?> get props => <Object?>[pay, amount];
}

/// Changes the amount of the pay already posted this cycle: *Change this month too* after a new
/// income amount, and its Undo (SPEC FR-SE-1, DECISIONS D137).
final class CorrectLatestPay implements UseCase<Entry, CorrectLatestPayParams> {
  const CorrectLatestPay({required this._ledger});

  final LedgerRepository _ledger;

  /// Returns [Right] with the entry as saved (its date, rule and created time kept), or [Left]
  /// with `EntryNotFoundFailure` or `DatabaseFailure`.
  @override
  TaskEither<Failure, Entry> call(CorrectLatestPayParams params) {
    final EntryDraft draft = params.pay.draft;
    return _ledger.replace(
      params.pay.id,
      EntryDraft(amount: params.amount, kind: draft.kind, categoryId: draft.categoryId, date: draft.date, note: draft.note),
    );
  }
}
