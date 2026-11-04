import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/data/datasource/entries_local_data_source.dart';
import 'package:expense_tracker/ledger/data/repository/ledger_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/saved_total.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/test_database.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);

EntryDraft _draft({int rupees = 60, CalendarDate date = _today, String? note = 'Chai'}) =>
    EntryDraft(amount: Money.fromMajor(rupees), kind: EntryKind.spent, categoryId: 1, date: date, note: note);

T _right<T>(Either<Failure, T> result) => result.getOrElse((Failure f) => fail(f.message));

void main() {
  late AppDatabase database;
  late LedgerRepositoryImpl repository;
  late List<void> changes;

  setUp(() async {
    database = await openTestDatabase();
    repository = LedgerRepositoryImpl(
      entries: SqfliteEntriesLocalDataSource(database),
      clock: FakeClock(DateTime(2026, 10, 26, 10, 30)),
    );
    changes = <void>[];
    repository.changes.listen(changes.add);
    addTearDown(repository.dispose);
  });

  group('LedgerRepositoryImpl.savedTotal (D120)', () {
    EntryDraft saved(int rupees, CalendarDate date) =>
        EntryDraft(amount: Money.fromMajor(rupees), kind: EntryKind.saved, categoryId: 11, date: date);

    test('savedTotal sums Saved entries and dates the first', () async {
      _right(await repository.add(saved(5000, const CalendarDate(2026, 10, 10))).run());
      _right(await repository.add(saved(500, _today)).run());
      _right(await repository.add(_draft(rupees: 420)).run());
      expect(
        _right(await repository.savedTotal().run()),
        Option<SavedTotal>.of(SavedTotal(total: Money.fromMajor(5500), since: const CalendarDate(2026, 10, 10))),
      );
    });

    test('savedTotal is none with no saves', () async {
      _right(await repository.add(_draft(rupees: 420)).run());
      expect(_right(await repository.savedTotal().run()), const Option<SavedTotal>.none());
    });

    test('savedTotal returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.savedTotal().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('LedgerRepositoryImpl', () {
    test('adds an entry and reads it back', () async {
      final Entry saved = _right(await repository.add(_draft()).run());
      expect(saved.note, 'Chai');
      expect(_right(await repository.entriesBetween(_today, _today).run()), <Entry>[saved]);
    });

    test('lists a range newest first and excludes dates outside it', () async {
      final Entry older = _right(await repository.add(_draft(date: _today.addDays(-1))).run());
      final Entry newer = _right(await repository.add(_draft()).run());
      _right(await repository.add(_draft(date: _today.addDays(-40))).run());
      expect(_right(await repository.entriesBetween(_today.addDays(-7), _today).run()), <Entry>[newer, older]);
    });

    test('notifies listeners after every write (BR-10)', () async {
      final Entry saved = _right(await repository.add(_draft()).run());
      _right(await repository.replace(saved.id, _draft(rupees: 80)).run());
      _right(await repository.delete(saved.id).run());
      _right(await repository.restore(saved).run());
      await pumpEventQueue();
      expect(changes, hasLength(4));
    });

    test('replace keeps the id and the recurring link', () async {
      final int id = await database.db.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.amountMinor: 820000,
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: 7,
        TransactionColumns.date: '2026-10-05',
        TransactionColumns.recurringId: null,
        TransactionColumns.createdAt: '2026-10-05T00:00:00',
      });
      final Entry replaced = _right(await repository.replace(id, _draft(rupees: 8500, note: null)).run());
      expect((replaced.id, replaced.amount, replaced.note), (id, Money.fromMajor(8500), null));
    });

    test('replace and delete return EntryNotFoundFailure for a missing id', () async {
      expect((await repository.replace(404, _draft()).run()).getLeft().toNullable(), isA<EntryNotFoundFailure>());
      expect((await repository.delete(404).run()).getLeft().toNullable(), isA<EntryNotFoundFailure>());
      expect(changes, isEmpty);
    });

    test('delete then restore brings back the same entry', () async {
      final Entry saved = _right(await repository.add(_draft()).run());
      expect(_right(await repository.delete(saved.id).run()), saved);
      expect(_right(await repository.entriesBetween(_today, _today).run()), isEmpty);
      expect(_right(await repository.restore(saved).run()), saved);
    });

    test('restoring an id that exists again is a DatabaseFailure', () async {
      final Entry saved = _right(await repository.add(_draft()).run());
      expect((await repository.restore(saved).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('a database error becomes DatabaseFailure', () async {
      await database.close();
      expect((await repository.add(_draft()).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('an unreadable stored row becomes InvalidDataFailure', () async {
      await database.db.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.amountMinor: 100,
        TransactionColumns.currency: 'XYZ',
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: 1,
        TransactionColumns.date: '2026-10-26',
        TransactionColumns.createdAt: '2026-10-26T00:00:00',
      });
      expect((await repository.entriesBetween(_today, _today).run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });

  group('LedgerRepositoryImpl keeps when an entry was first saved', () {
    late FakeClock clock;
    late LedgerRepositoryImpl timed;

    setUp(() {
      clock = FakeClock(DateTime(2026, 10, 26, 10, 30));
      timed = LedgerRepositoryImpl(entries: SqfliteEntriesLocalDataSource(database), clock: clock);
      addTearDown(timed.dispose);
    });

    Future<String> storedCreatedAt(int id) async => (await database.db.query(
          Tables.transactions,
          columns: <String>[TransactionColumns.createdAt],
          where: '${TransactionColumns.id} = ?',
          whereArgs: <Object?>[id],
        ))
            .single[TransactionColumns.createdAt]! as String;

    test('editing an entry keeps its original created time', () async {
      final Entry saved = _right(await timed.add(_draft()).run());
      clock.advance(const Duration(hours: 5));
      _right(await timed.replace(saved.id, _draft(rupees: 80)).run());
      expect(await storedCreatedAt(saved.id), DateTime(2026, 10, 26, 10, 30).toIso8601String());
    });

    test('Undo after delete restores the original created time', () async {
      final Entry saved = _right(await timed.add(_draft()).run());
      _right(await timed.delete(saved.id).run());
      clock.advance(const Duration(seconds: 4));
      _right(await timed.restore(saved).run());
      expect(await storedCreatedAt(saved.id), DateTime(2026, 10, 26, 10, 30).toIso8601String());
    });

    test('a new entry is stamped with the clock\'s now', () async {
      final Entry saved = _right(await timed.add(_draft()).run());
      expect(await storedCreatedAt(saved.id), DateTime(2026, 10, 26, 10, 30).toIso8601String());
    });
  });

  group('LedgerRepositoryImpl.firstLoggedOn (BR-12)', () {
    late FakeClock clock;
    late LedgerRepositoryImpl timed;

    setUp(() {
      clock = FakeClock(DateTime(2026, 10, 26, 23, 59));
      timed = LedgerRepositoryImpl(entries: SqfliteEntriesLocalDataSource(database), clock: clock);
      addTearDown(timed.dispose);
    });

    test('an empty ledger was never logged in', () async {
      expect(_right(await timed.firstLoggedOn().run()), const Option<CalendarDate>.none());
    });

    test('is the day the earliest entry was saved, not the date it was given', () async {
      _right(await timed.add(_draft(date: const CalendarDate(2026, 10, 4))).run());
      clock.advance(const Duration(days: 3));
      _right(await timed.add(_draft()).run());
      expect(_right(await timed.firstLoggedOn().run()), const Option<CalendarDate>.of(CalendarDate(2026, 10, 26)));
    });

    test('a database error becomes DatabaseFailure', () async {
      await database.close();
      expect((await timed.firstLoggedOn().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('an unreadable created time becomes InvalidDataFailure', () async {
      await database.db.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.amountMinor: 100,
        TransactionColumns.currency: 'INR',
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: 1,
        TransactionColumns.date: '2026-10-26',
        TransactionColumns.createdAt: 'yesterday',
      });
      expect((await timed.firstLoggedOn().run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });
}
