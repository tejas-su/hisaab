import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/month_start.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/domain/entities/budget_settings.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_state.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_summary.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/range_forecast.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/usecase/get_cycle_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late GetCycleSummary getCycleSummary;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    getCycleSummary = GetCycleSummary(
      ledger: ledger,
      recurring: recurring,
      settings: settings,
      periods: const PeriodCalculator(),
      clock: FakeClock(WorkedExample.now),
    );
  });

  tearDown(() => ledger.dispose());

  Future<CycleSummary> summary() async =>
      (await getCycleSummary(const NoParams()).run()).getOrElse((Failure failure) => fail(failure.message));

  group('GetCycleSummary', () {
    test('reproduces the SPEC worked example from ledger data', () async {
      final CycleSummary result = await summary();
      expect(result.cycle, const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)));
      expect(result.pool, Money.fromMajor(16650));
      expect(result.todayShare, Money.fromMajor(1850));
      expect(result.safeToday, Money.fromMajor(1430));
      expect(result.state, const OnTrack());
      expect(result.forecast, LastsTillPayday(Money.fromMajor(9300)));
    });

    test('allows entries back to the start of the previous cycle (BR-10)', () async {
      expect((await summary()).earliestEntryDate, const CalendarDate(2026, 9, 4));
    });

    test('a bill not yet posted but due after the cycle is not counted', () async {
      // Rent's next date (5 Nov) is after the cycle ends (3 Nov), so B is only electricity.
      expect((await summary()).pool, Money.fromMajor(16650));
    });

    test('a bill whose next date was missed still counts its later dates in the cycle', () async {
      recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        RecurringRule(
          id: 3,
          label: 'Electricity',
          amount: Money.fromMajor(1200),
          kind: WorkedExample.electricity.kind,
          categoryId: WorkedExample.electricity.categoryId,
          schedule: WorkedExample.electricity.schedule,
          nextDue: const CalendarDate(2026, 9, 29),
        ),
      ];
      expect((await summary()).pool, Money.fromMajor(16650));
    });

    test('My month starts on the 1st: cycles follow the calendar month', () async {
      settings.settings = const BudgetSettings(monthStart: MonthStart.firstOfMonth);
      final CycleSummary result = await summary();
      expect(result.cycle, const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)));
      expect(result.earliestEntryDate, const CalendarDate(2026, 9, 1));
    });

    test('no salary rule: calendar month, and no income is the NoIncome state (E10)', () async {
      recurring.rules = <RecurringRule>[];
      ledger.entries.removeWhere((Entry e) => e.recurringId == 1);
      final CycleSummary result = await summary();
      expect(result.cycle.start, const CalendarDate(2026, 10, 1));
      expect(result.state, const NoIncome());
    });

    test('keep aside reduces the pool', () async {
      settings.settings = BudgetSettings(keepAside: Money.fromMajor(1650));
      expect((await summary()).pool, Money.fromMajor(15000));
    });

    final List<(String, void Function())> failures = <(String, void Function())>[
      ('settings', () => settings.failure = DatabaseFailure('settings')),
      ('rules', () => recurring.failure = DatabaseFailure('rules')),
      ('entries', () => ledger.failure = DatabaseFailure('entries')),
    ];
    for (final (String name, void Function() breakIt) in failures) {
      test('returns DatabaseFailure when reading $name fails', () async {
        breakIt();
        final Either<Failure, CycleSummary> result = await getCycleSummary(const NoParams()).run();
        expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
      });
    }
  });
}
