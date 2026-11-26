import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/frequency.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/entities/schedule.dart';
import 'package:hisaab/ledger/domain/usecase/get_cycle_summary.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// BR-23 / D213: a saving's put-ins still to come reserve at most its gap to the target (AC-T9).
/// Worked example: today 26 Oct 2026, cycle 4 Oct to 3 Nov; the saving is due on 30 Oct.
void main() {
  RecurringRule saving({required int amount, int? target}) => RecurringRule(
        id: 5,
        label: 'Insurance',
        amount: Money.fromMajor(amount),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 30)),
        nextDue: const CalendarDate(2026, 10, 30),
        target: target == null ? const Option<Money>.none() : Option<Money>.of(Money.fromMajor(target)),
      );

  Entry putIn(int id, int rupees) => Entry(
        id: id,
        amount: Money.fromMajor(rupees),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 9, 30),
        createdAt: DateTime(2026, 9, 30, 12),
        recurringId: 5,
      );

  Future<CycleSummary> summaryWith(List<RecurringRule> extraRules, int putInRupees) async {
    final FakeLedgerRepository ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, putIn(800, putInRupees)]);
    addTearDown(ledger.dispose);
    final GetCycleSummary summary = GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, ...extraRules]),
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: FakeClock(WorkedExample.now),
    );
    return (await summary(const NoParams()).run()).getOrElse((Failure failure) => fail(failure.message));
  }

  test('reached_saving_reserves_nothing', () async {
    final CycleSummary reached = await summaryWith(<RecurringRule>[saving(amount: 1000, target: 12000)], 12000);
    final CycleSummary deleted = await summaryWith(const <RecurringRule>[], 12000);

    expect(reached.todayShare, deleted.todayShare);
    expect(reached, deleted);
  });

  test('partial_gap_caps_reservation', () async {
    final CycleSummary capped = await summaryWith(<RecurringRule>[saving(amount: 5000, target: 50000)], 47000);
    final CycleSummary exactly = await summaryWith(<RecurringRule>[saving(amount: 3000)], 47000);

    expect(capped.todayShare, exactly.todayShare);
    expect(capped, exactly);
  });

  test('no_target_reserves_the_full_put_in', () async {
    final CycleSummary plain = await summaryWith(<RecurringRule>[saving(amount: 5000)], 47000);
    final CycleSummary none = await summaryWith(const <RecurringRule>[], 47000);

    expect(plain.todayShare < none.todayShare, isTrue);
  });
}
