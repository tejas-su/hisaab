import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_draft.dart';
import '../../domain/entities/saved_total.dart';
import '../../domain/failures/ledger_failures.dart';
import '../../domain/repository/ledger_repository.dart';
import '../datasource/entries_local_data_source.dart';
import '../mapper/entry_mapper.dart';
import '../model/entry_model.dart';

/// [LedgerRepository] over sqflite; owns the [changes] stream, closed by [dispose].
final class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl({required this._entries, required this._clock});

  final EntriesLocalDataSource _entries;
  final Clock _clock;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  TaskEither<Failure, List<Entry>> entriesBetween(CalendarDate from, CalendarDate to) =>
      dbTask(() => _entries.between(from.toIso(), to.toIso()))
          .chainEither((List<EntryModel> models) => models.traverseEither(EntryMapper.toEntity));

  @override
  TaskEither<Failure, Entry> add(EntryDraft draft) => dbTask(
        () => _entries.insert(EntryMapper.toModel(draft, createdAt: _clock.now())),
      ).flatMap(_found).map(_notify);

  @override
  TaskEither<Failure, Entry> replace(int id, EntryDraft draft) => _found(id)
      .flatMap(
        (Entry current) => dbTask(
          () => _entries.update(
            id,
            EntryMapper.toModel(draft, createdAt: current.createdAt, id: id, recurringId: current.recurringId),
          ),
        ),
      )
      .flatMap((int _) => _found(id))
      .map(_notify);

  @override
  TaskEither<Failure, Entry> delete(int id) => _found(id)
      .flatMap((Entry entry) => dbTask(() => _entries.delete(id)).map((int _) => entry))
      .map(_notify);

  @override
  TaskEither<Failure, Entry> restore(Entry entry) => dbTask(
        () => _entries.insert(
          EntryMapper.toModel(entry.draft, createdAt: entry.createdAt, id: entry.id, recurringId: entry.recurringId),
        ),
      ).flatMap(_found).map(_notify);

  @override
  TaskEither<Failure, Option<CalendarDate>> firstLoggedOn() => dbTask(_entries.firstCreatedAt).chainEither(
        (String? text) => Option<String>.fromNullable(text).match(
          () => Either<Failure, Option<CalendarDate>>.right(const Option<CalendarDate>.none()),
          (String createdAt) => _dayOf(createdAt).map(Option<CalendarDate>.of),
        ),
      );

  @override
  TaskEither<Failure, Option<SavedTotal>> savedTotal() => dbTask(_entries.savedTotal).chainEither(
        (({int totalMinor, String? firstDate}) row) => Option<String>.fromNullable(row.firstDate).match(
          () => Either<Failure, Option<SavedTotal>>.right(const Option<SavedTotal>.none()),
          (String first) => CalendarDate.parse(first)
              .map((CalendarDate since) => Option<SavedTotal>.of(SavedTotal(total: Money(row.totalMinor), since: since))),
        ),
      );

  /// Closes [changes]; call when the app's composition root is torn down.
  Future<void> dispose() => _changes.close();

  static Either<Failure, CalendarDate> _dayOf(String createdAt) =>
      Option<DateTime>.fromNullable(DateTime.tryParse(createdAt))
          .map(CalendarDate.fromDateTime)
          .toEither<Failure>(() => InvalidDataFailure('Bad created_at "$createdAt"'));

  TaskEither<Failure, EntryModel> _existing(int id) => dbTask(() => _entries.byId(id)).chainEither(
        (EntryModel? model) =>
            Option<EntryModel>.fromNullable(model).toEither<Failure>(() => EntryNotFoundFailure('No entry $id')),
      );

  TaskEither<Failure, Entry> _found(int id) => _existing(id).chainEither(EntryMapper.toEntity);

  Entry _notify(Entry entry) {
    _changes.add(null);
    return entry;
  }
}
