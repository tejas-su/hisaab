import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';

/// Whether income is set up, so *Can I afford it?* has money to weigh (SPEC FR-SP-9 AC-1,
/// FR-WG-9 AC-2, D223): a salary rule exists, or a *Got* has ever been recorded (*It changes*).
/// The Spends card and the shortcut both ask this, so they never disagree.
final class IsIncomeSetUp implements UseCase<bool, NoParams> {
  const IsIncomeSetUp({required this._getIncome, required this._ledger});

  final GetIncome _getIncome;
  final LedgerRepository _ledger;

  /// Returns [Right] with whether income is set up, or [Left] with `DatabaseFailure` when a read
  /// fails.
  @override
  TaskEither<Failure, bool> call(NoParams params) => _getIncome(params).flatMap(
    (Income income) => income.rule.isSome()
        ? TaskEither<Failure, bool>.of(true)
        : _ledger.anyGot(),
  );
}
