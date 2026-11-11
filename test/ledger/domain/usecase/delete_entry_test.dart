import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:hisaab/ledger/domain/usecase/delete_entry.dart';
import 'package:hisaab/ledger/domain/usecase/restore_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;

  setUp(() => ledger = FakeLedgerRepository(WorkedExample.entries));
  tearDown(() => ledger.dispose());

  group('DeleteEntry', () {
    test('deletes and returns the entry so it can be undone (BR-10)', () async {
      final Either<Failure, Entry> result = await DeleteEntry(ledger: ledger)(4).run();
      expect(result, Either<Failure, Entry>.right(WorkedExample.entries[3]));
      expect(ledger.entries.map((Entry e) => e.id), isNot(contains(4)));
    });

    test('returns EntryNotFoundFailure for a missing id', () async {
      final Either<Failure, Entry> result = await DeleteEntry(ledger: ledger)(404).run();
      expect(result.getLeft().toNullable(), isA<EntryNotFoundFailure>());
    });
  });

  group('RestoreEntry', () {
    test('puts the deleted entry back unchanged, recurring link included', () async {
      final Entry rent = WorkedExample.entries[1];
      await DeleteEntry(ledger: ledger)(rent.id).run();
      final Either<Failure, Entry> result = await RestoreEntry(ledger: ledger)(rent).run();
      expect(result, Either<Failure, Entry>.right(rent));
      expect(ledger.entries, contains(rent));
    });

    test('passes a database failure through', () async {
      ledger.failure = DatabaseFailure('locked');
      final Either<Failure, Entry> result = await RestoreEntry(ledger: ledger)(WorkedExample.entries.first).run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
