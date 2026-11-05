import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
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
  late FakeRecurringRepository recurring;
  late SaveEntry saveEntry;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    saveEntry = SaveEntry(ledger: ledger, recurring: recurring, clock: FakeClock(WorkedExample.now));
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

  group('SaveEntry, editing an entered bill (D123)', () {
    final RecurringRule electricity = WorkedExample.electricity.copyWith(amountMode: AmountMode.varies);
    const CalendarDate oct20 = CalendarDate(2026, 10, 20);
    Entry entered(int id, CalendarDate date) => Entry(
          id: id,
          amount: Money.fromMajor(1460),
          kind: EntryKind.spent,
          categoryId: SeedCategoryIds.bills,
          date: date,
          createdAt: WorkedExample.now,
          recurringId: electricity.id,
        );
    EntryDraft edit(CalendarDate date, {int rupees = 1500}) =>
        EntryDraft(amount: Money.fromMajor(rupees), kind: EntryKind.spent, categoryId: SeedCategoryIds.bills, date: date);

    setUp(() {
      recurring.rules = <RecurringRule>[WorkedExample.salary, electricity];
      ledger.entries.add(entered(20, oct20));
    });

    test('a new amount for the latest entry becomes next month\'s estimate', () async {
      await saveEntry(SaveEntryParams(edit(oct20), replacing: const Option<int>.of(20))).run();
      expect(recurring.updates.single, electricity.copyWith(amount: Money.fromMajor(1500)));
    });

    test('an older entry leaves the estimate alone', () async {
      ledger.entries.add(entered(21, const CalendarDate(2026, 10, 25)));
      await saveEntry(SaveEntryParams(edit(oct20), replacing: const Option<int>.of(20))).run();
      expect(recurring.updates, isEmpty);
    });

    test('the same amount writes nothing to the bill', () async {
      await saveEntry(SaveEntryParams(edit(oct20, rupees: 1200), replacing: const Option<int>.of(20))).run();
      expect(recurring.updates, isEmpty);
    });

    test('a fixed bill\'s entry leaves its rule alone', () async {
      await saveEntry(SaveEntryParams(edit(const CalendarDate(2026, 10, 5)), replacing: const Option<int>.of(2))).run();
      expect(recurring.updates, isEmpty);
    });

    test('a typed entry never touches the bills', () async {
      await saveEntry(SaveEntryParams(_draft(rupees: 75), replacing: const Option<int>.of(4))).run();
      expect(recurring.updates, isEmpty);
    });

    test('the edit is saved even when the bills can\'t be read', () async {
      recurring.failure = DatabaseFailure('locked');
      final Either<Failure, Entry> result = await saveEntry(SaveEntryParams(edit(oct20), replacing: const Option<int>.of(20))).run();
      expect(result.map((Entry e) => e.amount), Either<Failure, Money>.right(Money.fromMajor(1500)));
    });
  });
}
