import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/domain/entities/cycle_state.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/range_forecast.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/entities/week_day.dart';
import 'package:hisaab/ledger/domain/entities/yesterday_saving.dart';
import 'package:hisaab/ledger/domain/usecase/get_cycle_summary.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// BR-18 against the BR-4 worked example: I 45,000, B 1,200, S_prev 27,150, ₹420 today, D 9.
/// Before any fix: P 16,650, A 1,850, hero 1,430, remaining 16,230 (H 17,430).
void main() {
  late FakeLedgerRepository ledger;
  late GetCycleSummary getCycleSummary;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    getCycleSummary = GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules]),
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: FakeClock(WorkedExample.now),
    );
  });

  tearDown(() => ledger.dispose());

  Future<CycleSummary> summary() async =>
      (await getCycleSummary(const NoParams()).run()).getOrElse((Failure failure) => fail(failure.message));

  const CalendarDate today = WorkedExample.today;

  group('a fix is never spending (BR-3 to BR-8)', () {
    test('summary exposes income, billsDue, savingsDue and fixedToday', () async {
      final CycleSummary before = await summary();

      expect(before.income, Money.fromMajor(45000));
      expect(before.billsDue, Money.fromMajor(1200));
      expect(before.savingsDue, Money.zero);
      expect(before.fixedToday, Money.zero);
      expect(before.remaining + before.billsDue + before.savingsDue, Money.fromMajor(17430));
    });

    test('a Spent fix today is F_t: pool 16,650 to 12,450, A 1,383, hero 963, S_today stays 420', () async {
      ledger.entries.add(notLogged(4200, today));

      final CycleSummary after = await summary();

      expect(after.fixedToday, Money.fromMajor(4200));
      expect(after.pool, Money.fromMajor(12450));
      expect(after.todayShare, Money.fromMajor(1383));
      expect(after.spentToday, Money.fromMajor(420));
      expect(after.safeToday, Money.fromMajor(963));
      expect(after.remaining, Money.fromMajor(12030));
      expect(after.state, isA<OnTrack>());
    });

    test('a Got fix is in I: A 1,961, hero 1,541', () async {
      ledger.entries.add(notLogged(1000, today, got: true));

      final CycleSummary after = await summary();

      expect(after.income, Money.fromMajor(46000));
      expect(after.pool, Money.fromMajor(17650));
      expect(after.todayShare, Money.fromMajor(1961));
      expect(after.safeToday, Money.fromMajor(1541));
      expect(after.remaining, Money.fromMajor(17230));
    });

    test('after a fix H equals T: 13,230 typed, remaining 12,030 plus B 1,200', () async {
      ledger.entries.add(notLogged(4200, today));

      final CycleSummary after = await summary();

      expect(after.remaining + after.billsDue + after.savingsDue, Money.fromMajor(13230));
    });

    test('a Spent fix dated yesterday is in S_prev, never in a bar or the week spent', () async {
      final CycleSummary before = await summary();
      ledger.entries.add(notLogged(4200, today.addDays(-1)));

      final CycleSummary after = await summary();

      expect(after.pool, Money.fromMajor(12450));
      expect(after.spentToday, Money.fromMajor(420));
      expect(after.spentThisWeek, before.spentThisWeek);
      expect(after.week.map((WeekDay d) => d.spent).toList(), before.week.map((WeekDay d) => d.spent).toList());
    });

    test("a fix is in its day's pool: that day's bar share is lower", () async {
      final CycleSummary before = await summary();
      ledger.entries.add(notLogged(4200, today.addDays(-1)));

      final CycleSummary after = await summary();

      expect(after.week.last.share < before.week.last.share, isTrue);
    });

    test('a fix is out of V_prev: the forecast spare is not cut by pace, a typed spend is', () async {
      ledger.entries.add(notLogged(1000, today.addDays(-2)));
      final RangeForecast withFix = (await summary()).forecast;
      ledger.entries.removeWhere((Entry e) => e.isNotLogged);
      ledger.entries.add(Entry(
        id: 801,
        amount: Money.fromMajor(1000),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: today.addDays(-2),
        createdAt: DateTime(2026, 10, 24, 9),
      ));
      final RangeForecast withTyped = (await summary()).forecast;

      expect(withFix, isA<LastsTillPayday>());
      expect(withTyped, isA<LastsTillPayday>());
      expect((withFix as LastsTillPayday).spare > (withTyped as LastsTillPayday).spare, isTrue);
    });

    test('the morning note after a fix dated yesterday credits and blames nothing (BR-8, E87)', () async {
      ledger.entries.add(notLogged(4200, today.addDays(-1)));

      final CycleSummary after = await summary();

      // why: A_yesterday is rebuilt with the fix as pool, so "A today = A yesterday + X / D" still holds.
      final YesterdaySaving note = after.savedYesterday.toNullable()!;
      expect(note.saved, Money.fromMajor(1245));
      expect(after.todayShare, note.saved + note.eachDayMore);
    });

    test('a lower A below what was spent today: OverToday (E75)', () async {
      ledger.entries.add(notLogged(15000, today));

      final CycleSummary after = await summary();

      expect(after.pool, Money.fromMajor(1650));
      expect(after.todayShare, Money.fromMajor(183));
      expect(after.state, isA<OverToday>());
      expect(after.safeToday.isNegative, isTrue);
    });

    test('remaining below zero after a fix: OverCycle (E76)', () async {
      ledger.entries.add(notLogged(16300, today));

      final CycleSummary after = await summary();

      expect(after.state, isA<OverCycle>());
    });

    test('overToday is never caused by a fix being counted as spending', () async {
      ledger.entries.add(notLogged(1800, today));

      final CycleSummary after = await summary();

      expect(after.spentToday, Money.fromMajor(420));
      expect(after.state, isNot(isA<OverToday>()));
    });
  });
}
