import 'package:expense_tracker/ledger/domain/entities/amount_mode.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/occurrence.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_posting.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';
import 'package:expense_tracker/ledger/domain/usecase/post_due_recurring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

final RecurringRule _weeklyMilk = RecurringRule(
  id: 7,
  label: 'Milk',
  amount: Money.fromMajor(300),
  kind: EntryKind.spent,
  categoryId: 1,
  schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 9, 18)),
  nextDue: const CalendarDate(2026, 9, 18),
);

void main() {
  late FakeRecurringRepository recurring;
  late PostDueRecurring postDue;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    postDue = PostDueRecurring(recurring: recurring, clock: FakeClock(WorkedExample.now));
  });

  group('PostDueRecurring (BR-9)', () {
    test('posts nothing and writes nothing when no rule is due', () async {
      expect(await postDue(const NoParams()).run(), Either<Failure, int>.right(0));
      expect(recurring.postings, isEmpty);
    });

    test('E7: catches up every missed weekly occurrence and moves next_due past today', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, _weeklyMilk];
      final Either<Failure, int> result = await postDue(const NoParams()).run();
      expect(result, Either<Failure, int>.right(6));
      final RecurringPosting posting = recurring.postings.single;
      expect(posting.occurrences.map((Occurrence o) => o.date).toList(), <CalendarDate>[
        const CalendarDate(2026, 9, 18),
        const CalendarDate(2026, 9, 25),
        const CalendarDate(2026, 10, 2),
        const CalendarDate(2026, 10, 9),
        const CalendarDate(2026, 10, 16),
        const CalendarDate(2026, 10, 23),
      ]);
      expect(posting.occurrences.map((Occurrence o) => o.rule).toSet(), <RecurringRule>{_weeklyMilk});
      expect(posting.nextDueByRuleId, <int, CalendarDate>{7: const CalendarDate(2026, 10, 30)});
    });

    test('a deleted RD for this month is never re-posted: its next date has moved on', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      expect(await postDue(const NoParams()).run(), Either<Failure, int>.right(0));
    });

    test('saves catch up once each after weeks away (E-g)', () async {
      recurring.rules = <RecurringRule>[
        RecurringRule(
          id: WorkedExample.rd.id,
          label: 'RD',
          amount: WorkedExample.rd.amount,
          kind: EntryKind.saved,
          categoryId: WorkedExample.rd.categoryId,
          schedule: WorkedExample.rd.schedule,
          nextDue: const CalendarDate(2026, 10, 10),
        ),
      ];
      postDue = PostDueRecurring(recurring: recurring, clock: FakeClock(DateTime(2026, 11, 26, 9)));
      await postDue(const NoParams()).run();
      final RecurringPosting posting = recurring.postings.single;
      expect(posting.occurrences.map((Occurrence o) => o.date).toList(),
          <CalendarDate>[const CalendarDate(2026, 10, 10), const CalendarDate(2026, 11, 10)]);
      expect(posting.nextDueByRuleId, <int, CalendarDate>{4: const CalendarDate(2026, 12, 10)});
    });

    test('the engine posts nothing for a changing bill or a card bill, and leaves next_due (D123)', () async {
      const Schedule day20 = Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 20));
      final RecurringRule electricity = RecurringRule(
        id: 8,
        label: 'Electricity',
        amount: Money.fromMajor(1200),
        kind: EntryKind.spent,
        categoryId: 5,
        schedule: day20,
        nextDue: const CalendarDate(2026, 10, 20),
        amountMode: AmountMode.varies,
      );
      final RecurringRule card = RecurringRule(
        id: 9,
        label: 'Credit card',
        amount: Money.fromMajor(8000),
        kind: EntryKind.spent,
        categoryId: 12,
        schedule: day20,
        nextDue: const CalendarDate(2026, 10, 20),
        amountMode: AmountMode.card,
      );
      recurring.rules = <RecurringRule>[electricity, card, _weeklyMilk];
      await postDue(const NoParams()).run();
      final RecurringPosting posting = recurring.postings.single;
      expect(posting.occurrences.map((Occurrence o) => o.rule.id).toSet(), <int>{_weeklyMilk.id});
      expect(posting.nextDueByRuleId.keys, <int>[_weeklyMilk.id]);
    });

    test('posts an occurrence due today', () async {
      recurring.rules = <RecurringRule>[
        RecurringRule(
          id: 8,
          label: 'Gym',
          amount: Money.fromMajor(999),
          kind: EntryKind.spent,
          categoryId: 6,
          schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 26)),
          nextDue: WorkedExample.today,
        ),
      ];
      await postDue(const NoParams()).run();
      expect(recurring.postings.single.nextDueByRuleId, <int, CalendarDate>{8: const CalendarDate(2026, 11, 26)});
    });

    test('E9: a clock moved backwards posts nothing and never moves next_due back', () async {
      recurring.rules = <RecurringRule>[_weeklyMilk];
      final PostDueRecurring inThePast =
          PostDueRecurring(recurring: recurring, clock: FakeClock(DateTime(2026, 9, 1)));
      expect(await inThePast(const NoParams()).run(), Either<Failure, int>.right(0));
      expect(recurring.postings, isEmpty);
    });

    test('passes a database failure through', () async {
      recurring.failure = DatabaseFailure('locked');
      final Either<Failure, int> result = await postDue(const NoParams()).run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
