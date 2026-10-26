import 'dart:async';

import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_draft.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:expense_tracker/ledger/domain/repository/ledger_repository.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [LedgerRepository]; set [failure] to make every call fail with it.
final class FakeLedgerRepository implements LedgerRepository {
  FakeLedgerRepository([List<Entry> entries = const <Entry>[]]) : entries = <Entry>[...entries];

  final List<Entry> entries;
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  Failure? failure;
  int _nextId = 1000;

  /// Every draft passed to [add] or [replace], in order.
  final List<EntryDraft> saved = <EntryDraft>[];

  TaskEither<Failure, T> _run<T>(T Function() action) {
    final Failure? current = failure;
    if (current != null) {
      return TaskEither<Failure, T>.left(current);
    }
    return TaskEither<Failure, T>.right(action());
  }

  void _notify() => _changes.add(null);

  @override
  TaskEither<Failure, List<Entry>> entriesBetween(CalendarDate from, CalendarDate to) => _run(
        () => entries.where((Entry e) => !e.date.isBefore(from) && !e.date.isAfter(to)).toList()
          ..sort((Entry a, Entry b) => b.id.compareTo(a.id)),
      );

  @override
  TaskEither<Failure, Entry> add(EntryDraft draft) => _run(() {
        saved.add(draft);
        final Entry entry = _entryFrom(_nextId++, draft);
        entries.add(entry);
        _notify();
        return entry;
      });

  @override
  TaskEither<Failure, Entry> replace(int id, EntryDraft draft) {
    final int index = entries.indexWhere((Entry e) => e.id == id);
    if (index < 0 && failure == null) {
      return TaskEither<Failure, Entry>.left(EntryNotFoundFailure('No entry $id'));
    }
    return _run(() {
      saved.add(draft);
      final Entry entry = _entryFrom(id, draft, recurringId: entries[index].recurringId, createdAt: entries[index].createdAt);
      entries[index] = entry;
      _notify();
      return entry;
    });
  }

  @override
  TaskEither<Failure, Entry> delete(int id) {
    final int index = entries.indexWhere((Entry e) => e.id == id);
    if (index < 0 && failure == null) {
      return TaskEither<Failure, Entry>.left(EntryNotFoundFailure('No entry $id'));
    }
    return _run(() {
      final Entry removed = entries.removeAt(index);
      _notify();
      return removed;
    });
  }

  @override
  TaskEither<Failure, Entry> restore(Entry entry) => _run(() {
        entries.add(entry);
        _notify();
        return entry;
      });

  @override
  TaskEither<Failure, Option<CalendarDate>> firstLoggedOn() => _run(
        () => Option<DateTime>.fromNullable(
          entries.map((Entry e) => e.createdAt).fold<DateTime?>(null, (DateTime? first, DateTime at) => first == null || at.isBefore(first) ? at : first),
        ).map(CalendarDate.fromDateTime),
      );

  @override
  Stream<void> get changes => _changes.stream;

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();

  /// The created time stamped on new entries; the fake has no clock.
  static final DateTime addedAt = DateTime(2026, 10, 26, 10, 30);

  static Entry _entryFrom(int id, EntryDraft draft, {int? recurringId, DateTime? createdAt}) => Entry(
        id: id,
        amount: draft.amount,
        kind: draft.kind,
        categoryId: draft.categoryId,
        date: draft.date,
        createdAt: createdAt ?? addedAt,
        note: draft.note,
        recurringId: recurringId,
      );
}
