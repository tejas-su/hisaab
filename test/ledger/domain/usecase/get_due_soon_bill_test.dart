import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

RecurringRule _bill(int id, int rupees, CalendarDate nextDue, {EntryKind kind = EntryKind.spent}) => RecurringRule(
      id: id,
      label: 'Bill $id',
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: SeedCategoryIds.bills,
      schedule: Schedule(frequency: Frequency.monthly, anchor: nextDue),
      nextDue: nextDue,
    );

void main() {
  late FakeRecurringRepository recurring;
  late GetDueSoonBill getDueSoon;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    getDueSoon = GetDueSoonBill(recurring: recurring, clock: FakeClock(WorkedExample.now));
  });

  Future<Option<DueSoonBill>> run() async =>
      (await getDueSoon(const NoParams()).run()).getOrElse((Failure f) => fail('unexpected $f'));

  group('GetDueSoonBill (BR-9 due-soon nudge, FR-HO-3)', () {
    test('worked example: Electricity ₹1,200 goes out in 3 days', () async {
      expect(
        await run(),
        Option<DueSoonBill>.of(
          DueSoonBill(
            rule: WorkedExample.electricity,
            dueDate: const CalendarDate(2026, 10, 29),
            daysAway: 3,
          ),
        ),
      );
    });

    test('shows only the soonest of several bills', () async {
      recurring.rules = <RecurringRule>[
        _bill(1, 500, const CalendarDate(2026, 10, 30)),
        _bill(2, 900, const CalendarDate(2026, 10, 28)),
        _bill(3, 100, const CalendarDate(2026, 10, 29)),
      ];
      expect((await run()).map((DueSoonBill b) => b.label), const Option<String>.of('Bill 2'));
    });

    test('a saving 2 days away is due soon (D120)', () async {
      final RecurringRule rd28 = WorkedExample.rd.copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 28)),
        nextDue: const CalendarDate(2026, 10, 28),
      );
      recurring.rules = <RecurringRule>[WorkedExample.salary, WorkedExample.rent, rd28];
      expect(
        await run(),
        Option<DueSoonBill>.of(DueSoonBill(rule: rd28, dueDate: const CalendarDate(2026, 10, 28), daysAway: 2)),
      );
    });

    test('a bill and a saving on the same day: the first rule wins', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd.copyWith(
          schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 29)),
          nextDue: const CalendarDate(2026, 10, 29),
        )];
      expect((await run()).map((DueSoonBill b) => b.rule), Option<RecurringRule>.of(WorkedExample.electricity));
    });

    test('on a tie, the first rule wins', () async {
      recurring.rules = <RecurringRule>[
        _bill(4, 500, const CalendarDate(2026, 10, 28)),
        _bill(7, 900, const CalendarDate(2026, 10, 28)),
      ];
      expect((await run()).map((DueSoonBill b) => b.label), const Option<String>.of('Bill 4'));
    });

    test('a bill due tomorrow is 1 day away', () async {
      recurring.rules = <RecurringRule>[_bill(1, 500, const CalendarDate(2026, 10, 27))];
      expect((await run()).map((DueSoonBill b) => b.daysAway), const Option<int>.of(1));
    });

    test('a bill exactly 5 days away is shown', () async {
      recurring.rules = <RecurringRule>[_bill(1, 500, const CalendarDate(2026, 10, 31))];
      expect((await run()).map((DueSoonBill b) => b.daysAway), const Option<int>.of(5));
    });

    test('a bill 6 days away is not shown', () async {
      recurring.rules = <RecurringRule>[_bill(1, 500, const CalendarDate(2026, 11, 1))];
      expect(await run(), const Option<DueSoonBill>.none());
    });

    test('income is never a nudge', () async {
      recurring.rules = <RecurringRule>[_bill(1, 45000, const CalendarDate(2026, 10, 27), kind: EntryKind.got)];
      expect(await run(), const Option<DueSoonBill>.none());
    });

    test('no rules, no nudge', () async {
      recurring.rules = <RecurringRule>[];
      expect(await run(), const Option<DueSoonBill>.none());
    });

    test('an occurrence due today or earlier is the engine\'s job; the next one is used', () async {
      recurring.rules = <RecurringRule>[
        RecurringRule(
          id: 1,
          label: 'Milk',
          amount: Money.fromMajor(60),
          kind: EntryKind.spent,
          categoryId: SeedCategoryIds.food,
          schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 15)),
          nextDue: const CalendarDate(2026, 10, 22),
        ),
      ];
      expect((await run()).map((DueSoonBill b) => b.dueDate), const Option<CalendarDate>.of(CalendarDate(2026, 10, 29)));
    });

    test('a bill crossing the month and year end counts calendar days', () async {
      getDueSoon = GetDueSoonBill(recurring: recurring, clock: FakeClock(DateTime(2026, 12, 30, 9)));
      recurring.rules = <RecurringRule>[_bill(1, 500, const CalendarDate(2027, 1, 2))];
      expect((await run()).map((DueSoonBill b) => b.daysAway), const Option<int>.of(3));
    });

    test('carries the rule it came from, so Home can open its bill sheet (D118)', () async {
      expect((await run()).map((DueSoonBill b) => b.rule), Option<RecurringRule>.of(WorkedExample.electricity));
    });

    test('returns the repository failure', () async {
      recurring.failure = const InvalidDataFailure('boom');
      expect(await getDueSoon(const NoParams()).run(), Either<Failure, Option<DueSoonBill>>.left(const InvalidDataFailure('boom')));
    });
  });
}
