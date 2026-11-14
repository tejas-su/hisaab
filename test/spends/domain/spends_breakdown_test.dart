import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/category_detail.dart';
import 'package:hisaab/spends/domain/entities/cycle_bar.dart';
import 'package:hisaab/spends/domain/entities/money_split.dart';
import 'package:hisaab/spends/domain/entities/spends_comparison.dart';
import 'package:hisaab/spends/domain/insight_rules.dart';
import 'package:hisaab/spends/domain/spends_breakdown.dart';

import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/september_story.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

Money _r(int rupees) => Money.fromMajor(rupees);

Entry _entry(int id, int rupees, CalendarDate date, {EntryKind kind = EntryKind.spent, int category = SeedCategoryIds.food, String? note, bool notLogged = false}) =>
    Entry(
      id: id,
      amount: _r(rupees),
      kind: kind,
      categoryId: category,
      date: date,
      createdAt: DateTime(date.year, date.month, date.day),
      note: note,
      isNotLogged: notLogged,
    );

List<Entry> get _octoberWithSaving => <Entry>[
      ...WorkedExample.entries,
      _entry(900, 1000, const CalendarDate(2026, 10, 5), kind: EntryKind.saved, category: SeedCategoryIds.saved),
    ];

InsightWindow get _octoberNow => InsightWindow(cycle: _october, asOf: WorkedExample.today, entries: _octoberWithSaving);
InsightWindow get _septemberWhole =>
    InsightWindow(cycle: SeptemberStory.september, asOf: SeptemberStory.september.end, entries: SeptemberStory.septemberEntries());

void main() {
  group('SpendsBreakdown.split (BR-21)', () {
    test('worked example: ₹16,430 not spent yet', () {
      final MoneySplit split = SpendsBreakdown.split(_octoberWithSaving);
      expect(split, MoneySplit(income: _r(45000), bills: _r(8200), saved: _r(1000), everyday: _r(19370), notLogged: Money.zero));
      expect(split.left, _r(16430));
      expect(split.hasIncome, isTrue);
    });

    test('Not logged comes off what is left; Used and card bills paid touch nothing', () {
      final MoneySplit split = SpendsBreakdown.split(<Entry>[
        ..._octoberWithSaving,
        _entry(901, 4200, WorkedExample.today, category: SeedCategoryIds.notLogged, notLogged: true),
        _entry(902, 9000, WorkedExample.today, kind: EntryKind.used, category: SeedCategoryIds.saved),
        _entry(903, 5000, WorkedExample.today, kind: EntryKind.cardPaid, category: SeedCategoryIds.cardPaid),
      ]);
      expect(split.notLogged, _r(4200));
      expect(split.left, _r(12230));
    });

    test('nothing at all: no income and nothing left', () {
      final MoneySplit split = SpendsBreakdown.split(const <Entry>[]);
      expect(split.hasIncome, isFalse);
      expect(split.left, Money.zero);
    });
  });

  group('SpendsBreakdown.comparison (BR-21)', () {
    test('worked example: ₹4,760 less than by this day in September', () {
      final SpendsComparison c = SpendsBreakdown.comparison(_octoberNow, _septemberWhole).getOrElse(() => fail('expected a comparison'));
      expect(c.change, _r(-4760));
      expect(c.wholeCycle, isFalse);
      expect(c.isSame, isFalse);
    });

    test('a finished cycle compares whole cycles: September is ₹7,500 less than August', () {
      final SpendsComparison c = SpendsBreakdown.comparison(
        _septemberWhole,
        InsightWindow(cycle: SeptemberStory.august, asOf: SeptemberStory.august.end, entries: SeptemberStory.augustEntries()),
      ).getOrElse(() => fail('expected a comparison'));
      expect(c.change, _r(-7500));
      expect(c.wholeCycle, isTrue);
    });

    test('a 31-day cycle on day 31 against a 30-day one uses the previous last day', () {
      final InsightWindow lastDay = InsightWindow(cycle: _october, asOf: _october.start.addDays(30), entries: const <Entry>[]);
      final InsightWindow september = InsightWindow(
        cycle: SeptemberStory.september,
        asOf: SeptemberStory.september.end,
        entries: <Entry>[_entry(1, 500, SeptemberStory.september.end)],
      );
      expect(SpendsBreakdown.comparison(lastDay, september).map((SpendsComparison c) => c.change), Option<Money>.of(_r(-500)));
    });

    test('both ₹0: no comparison', () {
      final InsightWindow empty = InsightWindow(cycle: _october, asOf: WorkedExample.today, entries: const <Entry>[]);
      final InsightWindow before = InsightWindow(cycle: SeptemberStory.september, asOf: SeptemberStory.september.end, entries: const <Entry>[]);
      expect(SpendsBreakdown.comparison(empty, before), const Option<SpendsComparison>.none());
    });

    test('under ₹100 apart is the same; exactly ₹100 is not', () {
      expect(SpendsComparison(change: _r(-99), wholeCycle: false).isSame, isTrue);
      expect(SpendsComparison(change: _r(99), wholeCycle: false).isSame, isTrue);
      expect(SpendsComparison(change: _r(100), wholeCycle: false).isSame, isFalse);
    });
  });

  group('SpendsBreakdown.details (BR-21, FR-SP-4 AC-R2)', () {
    test('each category: its change on the same day, its biggest 3 entries and its count', () {
      final Map<int, CategoryDetail> details = SpendsBreakdown.details(_octoberNow, previous: Option<InsightWindow>.of(_septemberWhole));
      final CategoryDetail food = details[SeedCategoryIds.food] ?? fail('expected food');
      expect(food.top.first.amount, _r(18950));
      expect(food.count, greaterThanOrEqualTo(2));
      expect(food.change.isSome(), isTrue);
    });

    test('ties: the earlier day first, then the entry saved first; at most 3', () {
      final List<Entry> four = <Entry>[
        _entry(4, 100, const CalendarDate(2026, 10, 9)),
        _entry(3, 100, const CalendarDate(2026, 10, 8)),
        _entry(2, 100, const CalendarDate(2026, 10, 8)),
        _entry(1, 50, const CalendarDate(2026, 10, 6)),
      ];
      final CategoryDetail food = SpendsBreakdown.details(
        InsightWindow(cycle: _october, asOf: WorkedExample.today, entries: four),
        previous: const Option<InsightWindow>.none(),
      )[SeedCategoryIds.food]!;
      expect(food.top.map((Entry e) => e.id), <int>[2, 3, 4]);
      expect(food.count, 4);
      expect(food.change, const Option<Money>.none());
    });

    test('a category new this cycle changes by its whole amount; Not logged has no row', () {
      final Map<int, CategoryDetail> details = SpendsBreakdown.details(
        InsightWindow(
          cycle: _october,
          asOf: WorkedExample.today,
          entries: <Entry>[
            _entry(1, 3600, const CalendarDate(2026, 10, 8), category: SeedCategoryIds.home),
            _entry(2, 4200, const CalendarDate(2026, 10, 8), category: SeedCategoryIds.notLogged, notLogged: true),
          ],
        ),
        previous: Option<InsightWindow>.of(
          InsightWindow(cycle: SeptemberStory.september, asOf: SeptemberStory.september.end, entries: const <Entry>[]),
        ),
      );
      expect(details[SeedCategoryIds.home]!.change, Option<Money>.of(_r(3600)));
      expect(details.containsKey(SeedCategoryIds.notLogged), isFalse);
    });
  });

  group('SpendsBreakdown.strip (BR-21, FR-SP-8)', () {
    const PayCycle july = PayCycle(start: CalendarDate(2026, 7, 4), end: CalendarDate(2026, 8, 3));
    final List<Entry> all = <Entry>[...SeptemberStory.augustEntries(), ...SeptemberStory.septemberEntries(), ..._octoberWithSaving];
    final List<StripCycle> window = <StripCycle>[
      (cycle: _october, cyclesBack: 0),
      (cycle: SeptemberStory.september, cyclesBack: 1),
      (cycle: SeptemberStory.august, cyclesBack: 2),
      (cycle: july, cyclesBack: 3),
    ];

    test('oldest first, from the first logged cycle; counts left over in finished cycles', () {
      final MonthsStrip strip = SpendsBreakdown.strip(
        window,
        entries: all,
        today: WorkedExample.today,
        firstLogged: Option<CalendarDate>.of(SeptemberStory.august.start),
      ).getOrElse(() => fail('expected a strip'));
      expect(strip.bars.map((CycleBar b) => b.cycle), <PayCycle>[SeptemberStory.august, SeptemberStory.september, _october]);
      expect(strip.bars.last.isRunning, isTrue);
      expect(strip.bars.last.daysLeft, 8);
      expect(strip.bars.first.left, _r(-2100));
      expect(strip.bars[1].left, _r(4400));
      expect(strip.counted, 2);
      expect(strip.leftOver, 1);
    });

    test('hidden with fewer than 2 finished cycles', () {
      expect(
        SpendsBreakdown.strip(window, entries: all, today: WorkedExample.today, firstLogged: Option<CalendarDate>.of(SeptemberStory.september.start)),
        const Option<MonthsStrip>.none(),
      );
    });

    test('hidden when the cycle shown has no money in', () {
      final List<Entry> noOctoberPay = all.where((Entry e) => !(e.kind == EntryKind.got && _october.contains(e.date))).toList();
      expect(
        SpendsBreakdown.strip(window, entries: noOctoberPay, today: WorkedExample.today, firstLogged: Option<CalendarDate>.of(july.start)),
        const Option<MonthsStrip>.none(),
      );
    });

    test('hidden when nothing was ever logged', () {
      expect(
        SpendsBreakdown.strip(window, entries: all, today: WorkedExample.today, firstLogged: const Option<CalendarDate>.none()),
        const Option<MonthsStrip>.none(),
      );
    });

    test('a finished cycle without money in is drawn but not counted', () {
      final MonthsStrip strip = SpendsBreakdown.strip(
        window,
        entries: all,
        today: WorkedExample.today,
        firstLogged: Option<CalendarDate>.of(july.start),
      ).getOrElse(() => fail('expected a strip'));
      expect(strip.bars.first.cycle, july);
      expect(strip.bars.first.hasIncome, isFalse);
      expect(strip.counted, 2);
    });
  });
}
