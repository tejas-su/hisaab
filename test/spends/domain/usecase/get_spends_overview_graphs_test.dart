import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/category_detail.dart';
import 'package:hisaab/spends/domain/entities/cycle_bar.dart';
import 'package:hisaab/spends/domain/entities/money_split.dart';
import 'package:hisaab/spends/domain/entities/spends_comparison.dart';
import 'package:hisaab/spends/domain/entities/spends_overview.dart';
import 'package:hisaab/spends/domain/usecase/get_spends_overview.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late FakeCategoryRepository categories;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[
      ...SeptemberStory.augustEntries(),
      ...SeptemberStory.septemberEntries(),
      ...WorkedExample.entries,
      Entry(
        id: 900,
        amount: Money.fromMajor(1000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 10, 5),
        createdAt: DateTime(2026, 10, 5),
      ),
    ]);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    categories = FakeCategoryRepository();
  });

  tearDown(() => ledger.dispose());

  Future<SpendsOverview> overview([int cyclesBack = 0]) async {
    final FakeClock clock = FakeClock(WorkedExample.now);
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

  group('GetSpendsOverview: the graphs (BR-21)', () {
    test('worked example: the split is ₹16,430 not spent yet', () async {
      final MoneySplit split = (await overview()).split;
      expect(split.left, Money.fromMajor(16430));
      expect(split.bills, Money.fromMajor(8200));
      expect(split.everyday, Money.fromMajor(19370));
    });

    test('worked example: ₹4,760 less than by this day in September', () async {
      expect(
        (await overview()).comparison,
        Option<SpendsComparison>.of(SpendsComparison(change: Money.fromMajor(-4760), wholeCycle: false)),
      );
    });

    test('each category carries its detail; Food\'s biggest is ₹18,950', () async {
      final CategoryDetail food = (await overview()).details[SeedCategoryIds.food] ?? fail('expected food');
      expect(food.top.first.amount, Money.fromMajor(18950));
      expect(food.change.isSome(), isTrue);
    });

    test('the strip runs August to October, oldest first', () async {
      final MonthsStrip strip = (await overview()).strip.getOrElse(() => fail('expected a strip'));
      expect(strip.bars.map((CycleBar b) => b.cycle), <PayCycle>[SeptemberStory.august, SeptemberStory.september, (await overview()).cycle]);
      expect(strip.bars.map((CycleBar b) => b.cyclesBack), <int>[2, 1, 0]);
    });

    test('a finished September compares whole cycles and its strip ends at September, after August', () async {
      final SpendsOverview september = await overview(1);
      expect(september.comparison.map((SpendsComparison c) => (c.change, c.wholeCycle)), Option<(Money, bool)>.of((Money.fromMajor(-7500), true)));
      expect(september.split.left, Money.fromMajor(4400));
      final MonthsStrip strip = september.strip.getOrElse(() => fail('expected a strip'));
      expect(strip.bars.map((CycleBar b) => b.cycle), <PayCycle>[SeptemberStory.august, SeptemberStory.september]);
    });

    test('August, the first tracked cycle, has no comparison and no row changes', () async {
      final SpendsOverview august = await overview(2);
      expect(august.comparison, const Option<SpendsComparison>.none());
      expect(august.details.values.every((CategoryDetail d) => d.change.isNone()), isTrue);
    });
  });
}
