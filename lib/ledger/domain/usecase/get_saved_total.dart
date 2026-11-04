import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/saved_total.dart';
import '../repository/ledger_repository.dart';

/// Loads everything ever put into savings, for the Savings list footer (D120).
final class GetSavedTotal implements UseCase<Option<SavedTotal>, NoParams> {
  const GetSavedTotal({required this._ledger});

  final LedgerRepository _ledger;

  /// Returns [Right] with the total, or [None] before the first saving; or [Left] with
  /// `DatabaseFailure` or `InvalidDataFailure`.
  @override
  TaskEither<Failure, Option<SavedTotal>> call(NoParams params) => _ledger.savedTotal();
}
