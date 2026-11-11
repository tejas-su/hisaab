import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_draft.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/saved_total.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:hisaab/ledger/domain/repository/ledger_repository.dart';
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

  /// When set, the next [entriesBetween] read takes the entries as they are now but answers
  /// only once this completes, so a test can finish a later read first.
  Completer<void>? nextReadGate;

  @override
  TaskEither<Failure, List<Entry>> entriesBetween(CalendarDate from, CalendarDate to) {
    final Completer<void>? gate = nextReadGate;
    nextReadGate = null;
    final TaskEither<Failure, List<Entry>> read = _run(
      () => entries.where((Entry e) => !e.date.isBefore(from) && !e.date.isAfter(to)).toList()
        ..sort((Entry a, Entry b) => b.id.compareTo(a.id)),
    );
    return gate == null ? read : TaskEither<Failure, Unit>(() async {
      await gate.future;
      return Either<Failure, Unit>.right(unit);
    }).flatMap((Unit _) => read);
  }

  /// Like [add], linked to [recurringId]; records the draft in [saved] too.
  @override
  TaskEither<Failure, Entry> addForRule(EntryDraft draft, {required int recurringId}) => _run(() {
        saved.add(draft);
        final Entry entry = _entryFrom(_nextId++, draft, recurringId: recurringId);
        entries.add(entry);
        _notify();
        return entry;
      });

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

  /// When set, the next [delete] waits for it before it removes anything, like a slow write.
  Completer<void>? nextDeleteGate;

  @override
  TaskEither<Failure, Entry> delete(int id) {
    final Completer<void>? gate = nextDeleteGate;
    nextDeleteGate = null;
    return gate == null ? _delete(id) : TaskEither<Failure, Unit>(() async {
      await gate.future;
      return Either<Failure, Unit>.right(unit);
    }).flatMap((Unit _) => _delete(id));
  }

  TaskEither<Failure, Entry> _delete(int id) {
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
  TaskEither<Failure, Option<SavedTotal>> savedTotal() => _run(() {
        final List<Entry> saves = entries.where((Entry e) => e.kind == EntryKind.saved).toList();
        if (saves.isEmpty) {
          return const Option<SavedTotal>.none();
        }
        return Option<SavedTotal>.of(SavedTotal(
          total: saves.fold(Money.zero, (Money total, Entry e) => total + e.amount),
          since: saves.map((Entry e) => e.date).reduce((CalendarDate a, CalendarDate b) => b.isBefore(a) ? b : a),
        ));
      });

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
