import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/usecase/is_income_set_up.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// Whether income is set up, for *Can I afford it?*'s card and shortcut (FR-SP-9 AC-1, FR-WG-9 AC-2).
void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late IsIncomeSetUp isIncomeSetUp;

  Entry entry(int id, EntryKind kind, CalendarDate date) => Entry(
    id: id,
    amount: Money.fromMajor(30000),
    kind: kind,
    categoryId: kind == EntryKind.got ? SeedCategoryIds.salary : SeedCategoryIds.food,
    date: date,
    createdAt: DateTime(date.year, date.month, date.day),
  );

  setUp(() {
    ledger = FakeLedgerRepository();
    recurring = FakeRecurringRepository();
    final FakeClock clock = FakeClock(WorkedExample.now);
    isIncomeSetUp = IsIncomeSetUp(
      getIncome: GetIncome(recurring: recurring, ledger: ledger, clock: clock),
      ledger: ledger,
    );
  });

  Future<Either<Failure, bool>> read() => isIncomeSetUp(const NoParams()).run();

  group('IsIncomeSetUp', () {
    test('a salary rule is income set up, before its first pay', () async {
      recurring.rules = <RecurringRule>[WorkedExample.salary];

      expect(await read(), Either<Failure, bool>.right(true));
    });

    test('It changes with pay last month and none this month is income set up', () async {
      ledger.entries.add(entry(1, EntryKind.got, const CalendarDate(2026, 9, 20)));

      expect(await read(), Either<Failure, bool>.right(true));
    });

    test('It changes with pay this month is income set up', () async {
      ledger.entries.add(entry(1, EntryKind.got, const CalendarDate(2026, 10, 1)));

      expect(await read(), Either<Failure, bool>.right(true));
    });

    test('no income rule and no Got ever is not set up, whatever was spent', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      ledger.entries.add(entry(1, EntryKind.spent, const CalendarDate(2026, 10, 2)));

      expect(await read(), Either<Failure, bool>.right(false));
    });

    test('an empty ledger is not set up', () async {
      expect(await read(), Either<Failure, bool>.right(false));
    });

    test('a failed read is Left', () async {
      ledger.failure = DatabaseFailure('x');

      expect((await read()).isLeft(), isTrue);
    });
  });
}
