import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';

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

  /// Overwrites entry [id] with [draft], keeping its recurring link.
  ///
  /// Returns [Right] with the updated entry, [Left] with `EntryNotFoundFailure` when [id] is
  /// gone, or `DatabaseFailure`.
  TaskEither<Failure, Entry> replace(int id, EntryDraft draft);

  /// Deletes entry [id].
  ///
  /// Returns [Right] with the deleted entry so Undo can [restore] it, [Left] with
  /// `EntryNotFoundFailure` when [id] is gone, or `DatabaseFailure`.
  TaskEither<Failure, Entry> delete(int id);

  /// Puts a deleted [entry] back with its original id and recurring link (Undo).
  ///
  /// Returns [Right] with the entry, or [Left] with `EntryNotFoundFailure` if the id is
  /// taken again, or `DatabaseFailure`.
  TaskEither<Failure, Entry> restore(Entry entry);

  /// Emits once after each successful write; never errors. Home and Spends reload on it.
  Stream<void> get changes;
}
