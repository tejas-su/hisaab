import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entities/saved_total.dart';
import '../entities/saving_totals.dart';

/// Reads and writes entries (SPEC BR-10). Every successful write emits on [changes].
abstract interface class LedgerRepository {
  /// Loads the entries dated from [from] to [to] inclusive, newest first.
  ///
  /// Returns [Right] with the entries (possibly empty), or [Left] with `DatabaseFailure`.
  TaskEither<Failure, List<Entry>> entriesBetween(CalendarDate from, CalendarDate to);

  /// Saves a new entry from an already validated [draft].
  ///
  /// Returns [Right] with the saved entry, or [Left] with `DatabaseFailure`.
  TaskEither<Failure, Entry> add(EntryDraft draft);

  /// Saves a new entry from an already validated [draft], linked to recurring rule [recurringId]:
  /// a changing bill's amount, entered on its occurrence's date (D123). Emits on [changes].
  ///
  /// Returns [Right] with the saved entry, or [Left] with `DatabaseFailure`, also when that rule
  /// already has an entry on that date.
  TaskEither<Failure, Entry> addForRule(EntryDraft draft, {required int recurringId});

  /// Saves a new *Used* entry from an already validated [draft], linked to the saving
  /// [savingId] (a rule's id) it was paid from (BR-19, D175). Emits on [changes].
  ///
  /// Returns [Right] with the saved entry, or [Left] with `DatabaseFailure`, also when no rule
  /// has that id.
  TaskEither<Failure, Entry> addForSaving(EntryDraft draft, {required int savingId});

  /// Overwrites entry [id] with [draft], keeping its recurring link and created time.
  ///
  /// Returns [Right] with the updated entry, [Left] with `EntryNotFoundFailure` when [id] is
  /// gone, or `DatabaseFailure`.
  TaskEither<Failure, Entry> replace(int id, EntryDraft draft);

  /// Deletes entry [id].
  ///
  /// Returns [Right] with the deleted entry so Undo can [restore] it, [Left] with
  /// `EntryNotFoundFailure` when [id] is gone, or `DatabaseFailure`.
  TaskEither<Failure, Entry> delete(int id);

  /// Puts a deleted [entry] back with its original id, recurring and saving links and created
  /// time (Undo).
  ///
  /// Returns [Right] with the entry, or [Left] with `EntryNotFoundFailure` if the id is
  /// taken again, or `DatabaseFailure`.
  TaskEither<Failure, Entry> restore(Entry entry);

  /// The day the earliest entry still in the ledger was saved: roughly when the app was first used.
  ///
  /// Returns [Right] with the day, or [None] for an empty ledger; or [Left] with
  /// `DatabaseFailure`, or `InvalidDataFailure` for an unreadable created time.
  TaskEither<Failure, Option<CalendarDate>> firstLoggedOn();

  /// Everything ever put into savings and the day of the first saving (D120).
  ///
  /// Returns [Right] with the total, or [None] when nothing has been saved; or [Left] with
  /// `DatabaseFailure`, or `InvalidDataFailure` for an unreadable date.
  TaskEither<Failure, Option<SavedTotal>> savedTotal();

  /// What was put into each saving by its rule and what was used from it, all time (BR-19).
  ///
  /// Returns [Right] with the totals (empty when nothing was put in or used), or [Left] with
  /// `DatabaseFailure`.
  TaskEither<Failure, SavingTotals> savingTotals();

  /// Emits once after each successful write; never errors. Home and Spends reload on it.
  Stream<void> get changes;
}
