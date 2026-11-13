import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../entities/saving_totals.dart';
import '../entities/set_aside_summary.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import '../set_aside.dart';

/// Loads what is set aside in each active saving, for the Savings list and the *Used* keypad (BR-19).
final class GetSetAside implements UseCase<SetAsideSummary, NoParams> {
  const GetSetAside({required this._recurring, required this._ledger});

  final RecurringRepository _recurring;
  final LedgerRepository _ledger;

  /// Returns [Right] with the summary (empty before any saving), or [Left] with `DatabaseFailure`.
  @override
  TaskEither<Failure, SetAsideSummary> call(NoParams params) => _recurring.activeRules().flatMap(
        (List<RecurringRule> rules) => _ledger.savingTotals().map(
          (SavingTotals totals) => SetAside.summarise(
            rules.where((RecurringRule rule) => rule.kind == EntryKind.saved).toList(),
            totals,
          ),
        ),
      );
}
