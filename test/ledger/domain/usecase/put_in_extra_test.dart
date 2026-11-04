import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:expense_tracker/ledger/domain/usecase/get_cycle_summary.dart';
import 'package:expense_tracker/ledger/domain/usecase/put_in_extra.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late PutInExtra putInExtra;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    final FakeClock clock = FakeClock(WorkedExample.now);
    putInExtra = PutInExtra(
      getCycleSummary: GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      ledger: ledger,
      categories: FakeCategoryRepository(),
      clock: clock,
    );
  });

  tearDown(() => ledger.dispose());

  void addPostedRd() {
    recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
    ledger.entries.add(Entry(
      id: 50,
      amount: WorkedExample.rd.amount,
      kind: EntryKind.saved,
      categoryId: SeedCategoryIds.saved,
      date: const CalendarDate(2026, 10, 10),
      createdAt: WorkedExample.now,
      recurringId: WorkedExample.rd.id,
    ));
  }

  group('PutInExtra (D120)', () {
    test('₹500 is saved today as an extra', () async {
      final Entry entry = (await putInExtra(Money.fromMajor(500)).run()).getOrElse((Failure f) => fail(f.message));
      expect(
        (entry.amount, entry.kind, entry.categoryId, entry.date, entry.note, entry.recurringId),
        (Money.fromMajor(500), EntryKind.saved, SeedCategoryIds.saved, WorkedExample.today, null, null),
      );
      expect(ledger.entries.last, entry);
    });

    test('the most it takes is what is left: ₹11,230', () async {
      addPostedRd();
      final int before = ledger.entries.length;
      expect((await putInExtra(Money.fromMajor(11231)).run()).getLeft().toNullable(), isA<PutInTooMuchFailure>());
      expect(ledger.entries, hasLength(before));
      expect((await putInExtra(Money.fromMajor(11230)).run()).isRight(), isTrue);
    });

    test('₹0 is refused', () async {
      expect((await putInExtra(Money.zero).run()).getLeft().toNullable(), isA<InvalidAmountFailure>());
    });
  });
}
