import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/ledger_setup.dart';
import '../entities/recurring_draft.dart';
import '../entities/recurring_posting.dart';
import '../entities/recurring_rule.dart';

/// Recurring rules and the engine's writes (SPEC BR-9). Rule edits ([add], [update],
/// [setActive]) emit on [changes]; the engine's posts don't.
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

  /// Saves a new active rule from [draft].
  ///
  /// Returns [Right] with the rule and its new id, or [Left] with `DatabaseFailure`.
  TaskEither<Failure, RecurringRule> add(RecurringDraft draft);

  /// Overwrites the active rule with [rule]'s id. Entries it already posted are not touched.
  ///
  /// Returns [Right] with [rule], [Left] with `RuleNotFoundFailure` when no active rule has that
  /// id, or `DatabaseFailure`.
  TaskEither<Failure, RecurringRule> update(RecurringRule rule);

  /// Stops (`active: false`) or resumes rule [id]; a stopped rule posts nothing but its past
  /// entries stay.
  ///
  /// Returns [Right] with [unit], [Left] with `RuleNotFoundFailure` when [id] doesn't exist, or
  /// `DatabaseFailure`.
  TaskEither<Failure, Unit> setActive(int id, {required bool active});

  /// Emits once after each successful [add], [update] or [setActive]; never errors.
  Stream<void> get changes;
}
