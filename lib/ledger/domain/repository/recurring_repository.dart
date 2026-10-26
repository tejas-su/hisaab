import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/ledger_setup.dart';
import '../entities/recurring_posting.dart';
import '../entities/recurring_rule.dart';

/// Recurring rules and the engine's writes (SPEC BR-9).
abstract interface class RecurringRepository {
  /// Loads the active rules.
  ///
  /// Returns [Right] with the rules (possibly empty), or [Left] with `DatabaseFailure`.
  TaskEither<Failure, List<RecurringRule>> activeRules();

  /// Posts [posting] in one transaction: inserts each occurrence (skipping any already posted
  /// for that rule and date) and moves each rule's `next_due`.
  ///
  /// Returns [Right] with the number of entries actually inserted, or [Left] with
  /// `DatabaseFailure`, in which case nothing was written.
  TaskEither<Failure, int> post(RecurringPosting posting);

  /// Replaces all rules and entries with [setup] in one transaction (onboarding only).
  ///
  /// Safe to repeat after a failure. Returns [Right] with [unit], or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Unit> startFresh(LedgerSetup setup);
}
