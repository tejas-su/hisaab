import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/spends_overview.dart';
import 'package:hisaab/spends/domain/usecase/get_spends_overview.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// The Spends overview with a *Not logged* fix: its own part, never inside Spent (BR-18, FR-SP-4a).
void main() {
  late FakeLedgerRepository ledger;

  setUp(() => ledger = FakeLedgerRepository(WorkedExample.entries));

  tearDown(() => ledger.dispose());

  Future<SpendsOverview> overview({int cyclesBack = 0}) async {
    final FakeClock clock = FakeClock(WorkedExample.now);
    final FakeRecurringRepository recurring = FakeRecurringRepository(WorkedExample.rules);
    final FakeBudgetSettingsRepository settings = FakeBudgetSettingsRepository();
    final FakeCategoryRepository categories = FakeCategoryRepository();
    final GetSpendsOverview useCase = GetSpendsOverview(
      ledger: ledger,
      recurring: recurring,
      settings: settings,
      categories: categories,
      suggestLimits: GetSuggestedLimits(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        categories: categories,
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      periods: const PeriodCalculator(),
      clock: clock,
    );
    return (await useCase(cyclesBack).run()).getOrElse((Failure f) => fail(f.message));
  }

  group('GetSpendsOverview with a Not logged entry', () {
    test('Spent ₹27,570 stays, and Not logged ₹4,200 is its own part', () async {
      ledger.entries.add(notLogged(4200, WorkedExample.today));

      final SpendsOverview result = await overview();

      expect(result.spent, Money.fromMajor(27570));
      expect(result.notLogged, Money.fromMajor(4200));
    });

    test('a Got fix adds no part, and a Used or Saved entry adds none either', () async {
      ledger.entries.add(notLogged(1000, WorkedExample.today, got: true));

      final SpendsOverview result = await overview();

      expect(result.notLogged, Money.zero);
      expect(result.spent, Money.fromMajor(27570));
    });

    test('it is in no row, no share and no pace line', () async {
      final SpendsOverview before = await overview();
      ledger.entries.add(notLogged(4200, WorkedExample.today));

      final SpendsOverview after = await overview();

      expect(after.rows, before.rows);
      expect(after.pace, before.pace);
    });

    test('a Got fix raises the budget the pace is read against, as income', () async {
      final SpendsOverview before = await overview();
      ledger.entries.add(notLogged(1000, WorkedExample.today, got: true));

      final SpendsOverview after = await overview();

      expect(after.budget, before.budget + Money.fromMajor(1000));
    });

    test('a past cycle shows its own fix', () async {
      ledger.entries.add(notLogged(700, const CalendarDate(2026, 9, 20)));

      final SpendsOverview previous = await overview(cyclesBack: 1);

      expect(previous.notLogged, Money.fromMajor(700));
      expect((await overview()).notLogged, Money.zero);
    });
  });
}
