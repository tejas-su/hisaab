import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:expense_tracker/ledger/domain/usecase/save_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

EntryDraft _draft({int rupees = 250, String? note}) => EntryDraft(
      amount: Money.fromMajor(rupees),
      kind: EntryKind.spent,
      categoryId: 1,
      date: WorkedExample.today,
      note: note,
    );

void main() {
  late FakeLedgerRepository ledger;
  late SaveEntry saveEntry;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    saveEntry = SaveEntry(ledger: ledger, clock: FakeClock(WorkedExample.now));
  });

  tearDown(() => ledger.dispose());

  group('SaveEntry', () {
    test('adds a new entry with the cleaned note', () async {
      final Either<Failure, Entry> result = await saveEntry(SaveEntryParams(_draft(note: ' DMart '))).run();
      expect(result.map((Entry e) => e.note), Either<Failure, String?>.right('DMart'));
      expect(ledger.saved.single, _draft(note: 'DMart'));
    });

    test('replaces an existing entry when editing (FR-AD-8)', () async {
      final Either<Failure, Entry> result =
          await saveEntry(SaveEntryParams(_draft(rupees: 75), replacing: const Option<int>.of(4))).run();
      expect(result.map((Entry e) => (e.id, e.amount)), Either<Failure, (int, Money)>.right((4, Money.fromMajor(75))));
    });

    test('returns the validation failure and saves nothing', () async {
      final Either<Failure, Entry> result = await saveEntry(SaveEntryParams(_draft(rupees: 0))).run();
      expect(result.getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(ledger.saved, isEmpty);
    });

    test('returns EntryNotFoundFailure when the edited entry is gone', () async {
      final Either<Failure, Entry> result =
          await saveEntry(SaveEntryParams(_draft(), replacing: const Option<int>.of(404))).run();
      expect(result.getLeft().toNullable(), isA<EntryNotFoundFailure>());
    });

    test('passes a database failure through', () async {
      ledger.failure = DatabaseFailure('disk full');
      final Either<Failure, Entry> result = await saveEntry(SaveEntryParams(_draft())).run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('params compare by value', () {
      expect(SaveEntryParams(_draft()), SaveEntryParams(_draft()));
    });
  });
}
