import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/saving_started.dart';

/// Undoes *Start saving* (SPEC FR-SP-9 AC-6, E164): deletes a new saving and every put-in it has
/// already posted, or puts a re-checked saving's amount and target back as they were (D221).
/// Nothing else changes.
final class UndoStartSaving implements UseCase<Unit, SavingStarted> {
  const UndoStartSaving({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with [unit], or [Left] with `RuleNotFoundFailure` when the saving is gone, or
  /// `DatabaseFailure`. A new saving's put-ins (none are older than its first due day, E164) are deleted and the saving stopped in one
  /// transaction, so a failure leaves both as they were.
  @override
  TaskEither<Failure, Unit> call(SavingStarted params) => params.previous.match(
    () => _recurring.removeWithPostedEntries(params.rule.id, since: params.rule.nextDue),
    (RecurringRule previous) => _restore(params.rule.id, previous),
  );

  // why: read fresh, so what the engine moved since (its next_due) is kept; only the amount and
  // target go back.
  TaskEither<Failure, Unit> _restore(int id, RecurringRule previous) =>
      _recurring
          .activeRules()
          .flatMap(
            (List<RecurringRule> rules) =>
                Option<RecurringRule>.fromNullable(
                  rules.where((RecurringRule r) => r.id == id).firstOrNull,
                ).match(
                  () => TaskEither<Failure, RecurringRule>.left(
                    RuleNotFoundFailure('No saving $id'),
                  ),
                  (RecurringRule fresh) => _recurring.update(
                    fresh.copyWith(
                      amount: previous.amount,
                      target: previous.target,
                    ),
                  ),
                ),
          )
          .map((RecurringRule _) => unit);
}
