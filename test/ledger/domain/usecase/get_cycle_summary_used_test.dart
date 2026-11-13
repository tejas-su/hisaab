import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/usecase/get_cycle_summary.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// BR-19: a *Used* entry moves no number. The inputs are the BR-19 table: I 45,000, B 1,200,
/// S_prev 27,150, ₹420 spent today and ₹1,000 saved in the cycle by the 12 insurance put-ins.
void main() {
  late FakeLedgerRepository ledger;
  late GetCycleSummary getCycleSummary;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
    getCycleSummary = GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, WorkedExample.insurance]),
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: FakeClock(WorkedExample.now),
    );
  });

  tearDown(() => ledger.dispose());

  Future<CycleSummary> summary() async =>
      (await getCycleSummary(const NoParams()).run()).getOrElse((Failure failure) => fail(failure.message));

  void addUsed(int rupees, CalendarDate date) => ledger.entries.add(
        Entry(
          id: 900,
          amount: Money.fromMajor(rupees),
          kind: EntryKind.used,
          categoryId: SeedCategoryIds.saved,
          date: date,
          createdAt: DateTime(date.year, date.month, date.day, 11),
          note: 'Insurance',
          savingId: 5,
        ),
      );

  group('GetCycleSummary with a Used entry (BR-19)', () {
    test('the BR-19 inputs give the BR-19 numbers before the use', () async {
      final CycleSummary before = await summary();

      expect(before.pool, Money.fromMajor(15650));
      expect(before.todayShare, Money.fromMajor(1738));
      expect(before.safeToday, Money.fromMajor(1318));
      expect(before.remaining, Money.fromMajor(15230));
      expect(before.tomorrowShare.toNullable(), Money.fromMajor(1903));
    });

    test("a used entry changes none of BR-3's terms", () async {
      final CycleSummary before = await summary();

      addUsed(12000, WorkedExample.today);
      final CycleSummary after = await summary();

      expect(after.pool, before.pool);
      expect(after.todayShare, before.todayShare);
      expect(after.spentToday, before.spentToday);
      expect(after.safeToday, Money.fromMajor(1318));
      expect(after.remaining, Money.fromMajor(15230));
      expect(after.tomorrowShare, before.tomorrowShare);
      expect(after.savedExtraToday, before.savedExtraToday);
      expect(after, before);
    });

    test('a used entry dated yesterday leaves the morning note unchanged (BR-8)', () async {
      final CycleSummary before = await summary();

      addUsed(12000, WorkedExample.today.addDays(-1));
      final CycleSummary after = await summary();

      expect(after.savedYesterday, before.savedYesterday);
      expect(after.week, before.week);
    });

    test('the pace forecast ignores a used entry (BR-7)', () async {
      final CycleSummary before = await summary();

      addUsed(12000, WorkedExample.today);

      expect((await summary()).forecast, before.forecast);
    });

    test('the wrong models are not what is built: the hero is not ₹0 and no extra was saved today', () async {
      addUsed(12000, WorkedExample.today);
      final CycleSummary after = await summary();

      expect(after.safeToday, isNot(Money.zero));
      expect(after.savedExtraToday, Money.zero);
    });
  });
}
