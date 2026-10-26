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
