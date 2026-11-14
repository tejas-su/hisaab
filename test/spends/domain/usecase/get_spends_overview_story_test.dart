import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/domain/entities/spends_overview.dart';
import 'package:hisaab/spends/domain/usecase/get_month_story.dart';
import 'package:hisaab/spends/domain/usecase/get_spends_overview.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late FakeCategoryRepository categories;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[...SeptemberStory.augustEntries(), ...SeptemberStory.septemberEntries()]);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    categories = FakeCategoryRepository();
  });

  tearDown(() => ledger.dispose());

  GetSpendsOverview overviewOn(CalendarDate today) {
    final FakeClock clock = FakeClock(DateTime(today.year, today.month, today.day, 10));
    return GetSpendsOverview(
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
  }

  Future<SpendsOverview> overview(int cyclesBack, {CalendarDate today = SeptemberStory.today}) async =>
      (await overviewOn(today)(cyclesBack).run()).getOrElse((Failure f) => fail(f.message));

  group('GetSpendsOverview: the month story (BR-20, FR-SP-7)', () {
    test('a finished September carries its story, with the worked example numbers', () async {
      final SpendsOverview september = await overview(1);
      expect(september.cycle, SeptemberStory.september);
      final MonthStory story = september.story.getOrElse(() => fail('expected a story'));
      expect(story.left, Money.fromMajor(4400));
      expect(story.comparison.map((StoryComparison c) => c.change), Option<Money>.of(Money.fromMajor(-7500)));
      expect(september.showsStoryRow, isFalse);
    });

    test('the current cycle has no story of its own', () async {
      expect((await overview(0)).story, const Option<MonthStory>.none());
    });

    test('day 2 of October shows the slim row for September', () async {
      expect((await overview(0)).showsStoryRow, isTrue);
    });

    test('day 8 of October no longer does', () async {
      expect((await overview(0, today: const CalendarDate(2026, 10, 11))).showsStoryRow, isFalse);
    });

    test('no slim row when September has too few entries (E116)', () async {
      ledger.entries.removeWhere((Entry e) => SeptemberStory.september.contains(e.date) && e.id > 15);
      expect((await overview(0)).showsStoryRow, isFalse);
      expect((await overview(1)).story, const Option<MonthStory>.none());
    });

    test('August has no page 5: nothing was logged before it began (E117)', () async {
      ledger.entries.addAll(<Entry>[
        for (int i = 0; i < 3; i++)
          Entry(
            id: 600 + i,
            amount: Money.fromMajor(100),
            kind: EntryKind.got,
            categoryId: 10,
            date: SeptemberStory.august.start.addDays(10 + i),
            createdAt: DateTime(2026, 8, 14 + i),
          ),
      ]);
      final MonthStory august = (await overview(2)).story.getOrElse(() => fail('expected a story'));
      expect(august.comparison, const Option<StoryComparison>.none());
    });
  });

  group('GetMonthStory', () {
    test('returns the story Spends shows for that cycle', () async {
      final Either<Failure, Option<MonthStory>> result = await GetMonthStory(overview: overviewOn(SeptemberStory.today))(1).run();
      final SpendsOverview september = await overview(1);
      expect(result, Either<Failure, Option<MonthStory>>.right(september.story));
    });

    test('passes a failed read on as Left', () async {
      ledger.failure = DatabaseFailure('locked');
      final Either<Failure, Option<MonthStory>> result = await GetMonthStory(overview: overviewOn(SeptemberStory.today))(1).run();
      expect(result.isLeft(), isTrue);
    });
  });
}
