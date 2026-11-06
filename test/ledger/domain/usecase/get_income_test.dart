import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late GetIncome getIncome;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(WorkedExample.entries);
    final FakeClock clock = FakeClock(WorkedExample.now);
    getIncome = GetIncome(recurring: recurring, ledger: ledger, clock: clock);
  });

  Future<Either<Failure, Income>> run() => getIncome(const NoParams()).run();

  group('GetIncome', () {
    test('returns the salary rule and the pay it posted last', () async {
      final Income income = (await run()).getOrElse((Failure f) => fail('unexpected $f'));
      expect(income.rule, Option<RecurringRule>.of(WorkedExample.salary));
      expect(income.latestPay.map((Entry e) => e.date), const Option<CalendarDate>.of(CalendarDate(2026, 10, 4)));
    });

    test('a typed Got entry on payday is not the rule\'s pay', () async {
      ledger.entries
        ..removeWhere((Entry e) => e.recurringId == WorkedExample.salary.id)
        ..add(
          Entry(
            id: 90,
            amount: Money.fromMajor(45000),
            kind: EntryKind.got,
            categoryId: SeedCategoryIds.salary,
            date: const CalendarDate(2026, 10, 4),
            createdAt: WorkedExample.now,
          ),
        );
      final Income income = (await run()).getOrElse((Failure f) => fail('unexpected $f'));
      expect(income.latestPay, const Option<Entry>.none());
    });

    test('"It changes" has no rule and no pay, and counts what came in this month', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      ledger.entries.add(Entry(
        id: 91,
        amount: Money.fromMajor(45000),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.salary,
        date: const CalendarDate(2026, 9, 30),
        createdAt: WorkedExample.now,
      ));
      expect(
        await run(),
        Either<Failure, Income>.right(Income(rule: const Option<RecurringRule>.none(), receivedThisMonth: Money.fromMajor(45000))),
      );
    });

    test('"It changes" passes an entries failure through', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      ledger.failure = DatabaseFailure('boom');
      expect((await run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('passes a rules failure through', () async {
      recurring.failure = DatabaseFailure('boom');
      expect(await run(), Either<Failure, Income>.left(DatabaseFailure('boom')));
    });

    test('passes an entries failure through', () async {
      ledger.failure = DatabaseFailure('boom');
      expect(await run(), Either<Failure, Income>.left(DatabaseFailure('boom')));
    });
  });
}
