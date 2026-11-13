import 'package:hisaab/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/core/time/pay_switch.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/shortcuts/domain/projection/projected_book.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late ProjectedBook book;

  setUp(() {
    book = ProjectedBook(
      entries: WorkedExample.entries,
      rules: WorkedExample.rules,
      skips: <BillSkip>[BillSkip(ruleId: WorkedExample.electricity.id, date: const CalendarDate(2026, 10, 29))],
      settings: const BudgetSettings(),
      firstLogged: const Option<CalendarDate>.of(CalendarDate(2026, 10, 4)),
    );
  });

  T right<T>(Either<Failure, T> result) => result.getOrElse((Failure f) => fail(f.message));

  group('ProjectedBook', () {
    test("reads entries newest first by date, then id, as the database does", () async {
      final List<Entry> read = right(await book.ledger.entriesBetween(const CalendarDate(2026, 10, 20), WorkedExample.today).run());
      expect(read.map((Entry e) => e.id), <int>[6, 5, 4, 3]);
    });

    test("today's typed spends come oldest first, without bills", () {
      expect(book.typedSpendsOn(WorkedExample.today).map((Entry e) => e.id), <int>[4, 5, 6]);
      expect(book.typedSpendsOn(const CalendarDate(2026, 10, 5)), isEmpty);
    });

    test('a post adds the entries, skips a skipped or posted day, and moves the next due', () async {
      book.runningOn = const CalendarDate(2026, 11, 5);
      final RecurringRule rent = WorkedExample.rent;
      final RecurringRule electricity = WorkedExample.electricity;
      final int posted = right(
        await book.recurring
            .post(RecurringPosting(
              occurrences: <Occurrence>[
                Occurrence(rule: rent, date: const CalendarDate(2026, 11, 5)),
                Occurrence(rule: rent, date: const CalendarDate(2026, 10, 5)),
                Occurrence(rule: electricity, date: const CalendarDate(2026, 10, 29)),
              ],
              nextDueByRuleId: <int, CalendarDate>{rent.id: const CalendarDate(2026, 12, 5)},
            ))
            .run(),
      );

      expect(posted, 1);
      final Entry entry = right(await book.ledger.entriesBetween(const CalendarDate(2026, 11, 5), const CalendarDate(2026, 11, 5)).run()).single;
      expect((entry.id, entry.recurringId, entry.amount, entry.note, entry.createdAt), (7, rent.id, rent.amount, null, DateTime(2026, 11, 5)));
      final List<RecurringRule> rules = right(await book.recurring.activeRules().run());
      expect(rules.map((RecurringRule r) => r.nextDue), <CalendarDate>[WorkedExample.salary.nextDue, const CalendarDate(2026, 12, 5), electricity.nextDue]);
    });

    test("a posted saving carries its rule's name, as the database's post does (D120)", () async {
      final ProjectedBook savings = ProjectedBook(
        entries: const <Entry>[],
        rules: <RecurringRule>[WorkedExample.rd],
        skips: const <BillSkip>[],
        settings: const BudgetSettings(),
        firstLogged: const Option<CalendarDate>.none(),
      )..runningOn = const CalendarDate(2026, 11, 10);
      right(await savings.recurring
          .post(RecurringPosting(occurrences: <Occurrence>[Occurrence(rule: WorkedExample.rd, date: const CalendarDate(2026, 11, 10))], nextDueByRuleId: const <int, CalendarDate>{}))
          .run());

      final List<Entry> read = right(await savings.ledger.entriesBetween(const CalendarDate(2026, 11, 10), const CalendarDate(2026, 11, 10)).run());
      expect(read.single.note, 'RD');
    });

    test('the first logged day is the stored one, or the first post on an empty ledger', () async {
      expect(right(await book.ledger.firstLoggedOn().run()), const Option<CalendarDate>.of(CalendarDate(2026, 10, 4)));
      final ProjectedBook empty = ProjectedBook(
        entries: const <Entry>[],
        rules: <RecurringRule>[WorkedExample.salary],
        skips: const <BillSkip>[],
        settings: const BudgetSettings(),
        firstLogged: const Option<CalendarDate>.none(),
      );
      expect(right(await empty.ledger.firstLoggedOn().run()), const Option<CalendarDate>.none());
      empty.runningOn = const CalendarDate(2026, 11, 4);
      right(await empty.recurring
          .post(RecurringPosting(occurrences: <Occurrence>[Occurrence(rule: WorkedExample.salary, date: const CalendarDate(2026, 11, 4))], nextDueByRuleId: const <int, CalendarDate>{}))
          .run());
      expect(right(await empty.ledger.firstLoggedOn().run()), const Option<CalendarDate>.of(CalendarDate(2026, 11, 4)));
    });

    test('reads skips in range and the stored settings', () async {
      expect(right(await book.recurring.skipsBetween(const CalendarDate(2026, 10, 1), const CalendarDate(2026, 10, 28)).run()), isEmpty);
      expect(right(await book.recurring.skipsBetween(const CalendarDate(2026, 10, 29), const CalendarDate(2026, 10, 29)).run()), hasLength(1));
      expect(right(await book.budget.read().run()), const BudgetSettings());
    });

    test('never changes on its own', () async {
      expect(book.ledger.changes, emitsDone);
      expect(book.recurring.changes, emitsDone);
    });

    test('takes no write but the engine\'s posts', () {
      final EntryDraft draft = WorkedExample.entries.first.draft;
      final List<void Function()> writes = <void Function()>[
        () => book.ledger.add(draft),
        () => book.ledger.addForRule(draft, recurringId: 1),
        () => book.ledger.replace(1, draft),
        () => book.ledger.delete(1),
        () => book.ledger.restore(WorkedExample.entries.first),
        () => book.ledger.savedTotal(),
        () => book.recurring.startFresh(const LedgerSetup(rules: <RecurringDraft>[])),
        () => book.recurring.add(WorkedExample.rent.draft),
        () => book.recurring.update(WorkedExample.rent),
        () => book.recurring.setActive(1, active: false),
        () => book.recurring.skip(BillSkip(ruleId: 1, date: WorkedExample.today)),
        () => book.recurring.unskip(BillSkip(ruleId: 1, date: WorkedExample.today)),
        () => book.budget.addPaySwitch(PaySwitch(on: WorkedExample.today, from: const MonthlyOnDay(4))),
      ];
      for (final void Function() write in writes) {
        expect(write, throwsUnsupportedError);
      }
    });
  });
  test('typedSpendsOn ignores a used entry (FR-WG-3, BR-19)', () {
    final ProjectedBook withUsed = ProjectedBook(
      entries: <Entry>[
        ...WorkedExample.entries,
        Entry(
          id: 90,
          amount: Money.fromMajor(4000),
          kind: EntryKind.used,
          categoryId: 11,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          note: 'Insurance',
          savingId: 5,
        ),
      ],
      rules: WorkedExample.rules,
      skips: const <BillSkip>[],
      settings: const BudgetSettings(),
      firstLogged: const Option<CalendarDate>.of(CalendarDate(2026, 10, 4)),
    );

    expect(withUsed.typedSpendsOn(WorkedExample.today).map((Entry e) => e.id), <int>[4, 5, 6]);
  });

  test('a projected ledger refuses the Used writes, as it refuses every other', () {
    expect(
      () => book.ledger.addForSaving(
        EntryDraft(amount: Money.fromMajor(1), kind: EntryKind.used, categoryId: 11, date: WorkedExample.today),
        savingId: 5,
      ),
      throwsUnsupportedError,
    );
    expect(() => book.ledger.savingTotals(), throwsUnsupportedError);
  });

}
