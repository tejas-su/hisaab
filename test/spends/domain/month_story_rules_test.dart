import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/category_spend.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/domain/month_story_rules.dart';

import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/september_story.dart';

StoryWindow _window({List<Entry>? entries, List<Entry>? previousEntries, bool previousTracked = true}) => StoryWindow(
      cycle: SeptemberStory.september,
      previous: SeptemberStory.august,
      entries: entries ?? SeptemberStory.septemberEntries(),
      previousEntries: previousEntries ?? SeptemberStory.augustEntries(),
      previousTracked: previousTracked,
      categories: seedCategories,
    );

Entry _entry(int id, int rupees, CalendarDate date, {EntryKind kind = EntryKind.spent, int category = SeedCategoryIds.food, int? recurringId, bool notLogged = false, String? note}) =>
    Entry(
      id: id,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: category,
      date: date,
      createdAt: DateTime(date.year, date.month, date.day),
      recurringId: recurringId,
      isNotLogged: notLogged,
      note: note,
    );

Money _r(int rupees) => Money.fromMajor(rupees);

void main() {
  group('MonthStoryRules.hasStory (BR-20)', () {
    test('a finished 30-day cycle with 31 entries has one', () {
      expect(MonthStoryRules.hasStory(SeptemberStory.september, today: SeptemberStory.today, entryCount: 31), isTrue);
    });

    test('exactly 10 entries is enough; 9 is not (E116)', () {
      expect(MonthStoryRules.hasStory(SeptemberStory.september, today: SeptemberStory.today, entryCount: 10), isTrue);
      expect(MonthStoryRules.hasStory(SeptemberStory.september, today: SeptemberStory.today, entryCount: 9), isFalse);
    });

    test('a cycle that has not ended has none, even on its last day', () {
      expect(MonthStoryRules.hasStory(SeptemberStory.september, today: SeptemberStory.september.end, entryCount: 31), isFalse);
    });

    test('a weekly cycle has none; a 28-day February has one (E116)', () {
      const PayCycle week = PayCycle(start: CalendarDate(2026, 9, 7), end: CalendarDate(2026, 9, 13));
      const PayCycle february = PayCycle(start: CalendarDate(2027, 2, 1), end: CalendarDate(2027, 2, 28));
      expect(MonthStoryRules.hasStory(week, today: SeptemberStory.today, entryCount: 40), isFalse);
      expect(MonthStoryRules.hasStory(february, today: const CalendarDate(2027, 3, 1), entryCount: 40), isTrue);
    });
  });

  group('MonthStoryRules.showsRow (FR-SP-7 AC-2)', () {
    const PayCycle october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

    test('days 1 to 7 of the cycle show it', () {
      expect(MonthStoryRules.showsRow(october, today: october.start), isTrue);
      expect(MonthStoryRules.showsRow(october, today: october.start.addDays(6)), isTrue);
    });

    test('day 8 does not', () {
      expect(MonthStoryRules.showsRow(october, today: october.start.addDays(7)), isFalse);
    });
  });

  group('MonthStoryRules.of: worked example (BR-20)', () {
    late MonthStory story;
    setUp(() => story = MonthStoryRules.of(_window()));

    test('page 1: 30 days and 31 entries', () {
      expect(story.cycle, SeptemberStory.september);
      expect(story.entryCount, 31);
    });

    test('page 2: ₹39,600 spent, ₹4,400 left over, ₹1,000 saved', () {
      expect(story.income, _r(45000));
      expect(story.bills, _r(9400));
      expect(story.everyday, _r(30200));
      expect(story.saved, _r(1000));
      expect(story.notLogged, Money.zero);
      expect(story.spent, _r(39600));
      expect(story.left, _r(4400));
      expect(story.hasIncome, isTrue);
    });

    test('page 3: the rows of Where it went, biggest first, summing to 100', () {
      expect(story.rows.map((CategorySpend r) => r.spent), <Money>[_r(12100), _r(9400), _r(7300), _r(6200), _r(3100), _r(1500)]);
      expect(story.rows.map((CategorySpend r) => r.percent), <int>[30, 24, 18, 16, 8, 4]);
    });

    test('page 4: share ₹1,153, biggest day Sat 12 Sep ₹4,850 "Train tickets", 9 quiet days', () {
      final StoryDays days = story.days.getOrElse(() => fail('expected days'));
      expect(days.perDay, hasLength(30));
      expect(days.share, Option<Money>.of(_r(1153)));
      expect(days.peakIndex, 8);
      expect(days.peak, _r(4850));
      expect(days.peakNote, const Option<String>.of('Train tickets'));
      expect(days.peakCategoryId, SeedCategoryIds.travel);
      expect(days.quietDays, 9);
    });

    test('page 4: the 5 Saturdays came to ₹15,840', () {
      final StoryWeekday weekday = story.days.flatMap((StoryDays d) => d.weekday).getOrElse(() => fail('expected weekday'));
      expect(weekday, StoryWeekday(weekday: DateTime.saturday, count: 5, total: _r(15840)));
    });

    test('page 5: ₹7,500 less than August; Shopping, Food and Fun moved most', () {
      final StoryComparison against = story.comparison.getOrElse(() => fail('expected comparison'));
      expect(against.previousSpent, _r(47100));
      expect(against.change, _r(-7500));
      expect(against.moves.map((CategoryMove m) => (m.category.id, m.change)), <(int, Money)>[
        (SeptemberStory.shopping, _r(-3900)),
        (SeedCategoryIds.food, _r(-2200)),
        (SeptemberStory.fun, _r(-1600)),
      ]);
    });

    test('all six pages, in order', () {
      expect(story.pages, StoryPage.values);
    });
  });

  group('MonthStoryRules.of: edge cases', () {
    test('over income: August itself is ₹3,100 more than came in (E119)', () {
      final MonthStory august = MonthStoryRules.of(StoryWindow(
        cycle: SeptemberStory.august,
        previous: SeptemberStory.august,
        entries: <Entry>[
          ...SeptemberStory.augustEntries(),
          _entry(600, 1000, SeptemberStory.august.start, kind: EntryKind.saved, category: SeedCategoryIds.saved, recurringId: 2),
        ],
        previousEntries: const <Entry>[],
        previousTracked: false,
        categories: seedCategories,
      ));
      expect(august.spent, _r(47100));
      expect(august.left, _r(-3100));
    });

    test('Not logged comes off what was left but is not Spent, a bar or a day', () {
      final MonthStory story = MonthStoryRules.of(_window(entries: <Entry>[
        ...SeptemberStory.septemberEntries(),
        _entry(900, 4200, SeptemberStory.september.start.addDays(2), category: SeedCategoryIds.notLogged, notLogged: true),
      ]));
      expect(story.notLogged, _r(4200));
      expect(story.spent, _r(39600));
      expect(story.left, _r(200));
      expect(story.days.map((StoryDays d) => d.quietDays), const Option<int>.of(9));
    });

    test('Used and card bills paid touch nothing', () {
      final MonthStory story = MonthStoryRules.of(_window(entries: <Entry>[
        ...SeptemberStory.septemberEntries(),
        _entry(901, 12000, SeptemberStory.september.start.addDays(3), kind: EntryKind.used, category: SeedCategoryIds.saved),
        _entry(902, 5000, SeptemberStory.september.start.addDays(3), kind: EntryKind.cardPaid, category: SeedCategoryIds.cardPaid),
      ]));
      expect(story.spent, _r(39600));
      expect(story.left, _r(4400));
      expect(story.saved, _r(1000));
    });

    test('no income: no share, and no income to keep from (E118)', () {
      final MonthStory story = MonthStoryRules.of(_window(
        entries: SeptemberStory.septemberEntries().where((Entry e) => e.kind != EntryKind.got).toList(),
      ));
      expect(story.hasIncome, isFalse);
      expect(story.days.flatMap((StoryDays d) => d.share), const Option<Money>.none());
    });

    test('bills larger than income leave no share', () {
      final MonthStory story = MonthStoryRules.of(_window(entries: <Entry>[
        ...SeptemberStory.septemberEntries(),
        _entry(903, 40000, SeptemberStory.september.start.addDays(2), category: SeedCategoryIds.bills, recurringId: 9),
      ]));
      expect(story.days.flatMap((StoryDays d) => d.share), const Option<Money>.none());
    });

    test('fewer than 7 days of everyday spending: no page 4 (E120)', () {
      final List<Entry> sixDays = <Entry>[
        for (int day = 0; day < 6; day++) _entry(700 + day, 500, SeptemberStory.september.start.addDays(day)),
      ];
      final MonthStory story = MonthStoryRules.of(_window(entries: sixDays));
      expect(story.days, const Option<StoryDays>.none());
      expect(story.pages, isNot(contains(StoryPage.days)));
    });

    test('exactly 7 days of everyday spending shows page 4', () {
      final List<Entry> sevenDays = <Entry>[
        for (int day = 0; day < 7; day++) _entry(700 + day, 500, SeptemberStory.september.start.addDays(day)),
      ];
      expect(MonthStoryRules.of(_window(entries: sevenDays)).days.isSome(), isTrue);
    });

    test('previous cycle not fully tracked: no page 5 (E117)', () {
      final MonthStory story = MonthStoryRules.of(_window(previousTracked: false));
      expect(story.comparison, const Option<StoryComparison>.none());
      expect(story.pages, <StoryPage>[StoryPage.month, StoryPage.kept, StoryPage.whereItWent, StoryPage.days, StoryPage.end]);
    });

    test('previous cycle with nothing spent: no page 5', () {
      final MonthStory story = MonthStoryRules.of(_window(previousEntries: <Entry>[SeptemberStory.augustEntries().first]));
      expect(story.comparison.isNone(), isTrue);
    });

    test('the same spending: a ₹0 change and no zero moves', () {
      final List<Entry> same = <Entry>[
        for (int day = 0; day < 7; day++) _entry(700 + day, 500, SeptemberStory.september.start.addDays(day)),
      ];
      final List<Entry> previous = <Entry>[_entry(800, 3500, SeptemberStory.august.start.addDays(3))];
      final StoryComparison against =
          MonthStoryRules.of(_window(entries: same, previousEntries: previous)).comparison.getOrElse(() => fail('expected comparison'));
      expect(against.change, Money.zero);
      expect(against.moves, isEmpty);
    });

    test('moves tie on size: the bigger amount this cycle comes first', () {
      final List<Entry> entries = <Entry>[
        for (int day = 0; day < 7; day++) _entry(700 + day, 100, SeptemberStory.september.start.addDays(day), category: SeedCategoryIds.travel),
        _entry(710, 2000, SeptemberStory.september.start, category: SeedCategoryIds.home),
      ];
      final List<Entry> previous = <Entry>[
        _entry(800, 1700, SeptemberStory.august.start, category: SeedCategoryIds.travel),
        _entry(801, 3000, SeptemberStory.august.start, category: SeedCategoryIds.home),
      ];
      final StoryComparison against =
          MonthStoryRules.of(_window(entries: entries, previousEntries: previous)).comparison.getOrElse(() => fail('expected comparison'));
      expect(against.moves.map((CategoryMove m) => m.category.id), <int>[SeedCategoryIds.home, SeedCategoryIds.travel]);
    });

    test('the biggest day ties go to the earliest; no note names nothing', () {
      final List<Entry> entries = <Entry>[
        for (int day = 0; day < 7; day++) _entry(700 + day, 900, SeptemberStory.september.start.addDays(day), note: day == 0 ? '  ' : null),
      ];
      final StoryDays days = MonthStoryRules.of(_window(entries: entries)).days.getOrElse(() => fail('expected days'));
      expect(days.peakIndex, 0);
      expect(days.peakNote, const Option<String>.none());
    });

    test('no weekday line when no weekday reaches 35%', () {
      final List<Entry> even = <Entry>[
        for (int day = 0; day < 28; day++) _entry(700 + day, 100, SeptemberStory.september.start.addDays(day)),
      ];
      final StoryDays days = MonthStoryRules.of(_window(entries: even)).days.getOrElse(() => fail('expected days'));
      expect(days.weekday, const Option<StoryWeekday>.none());
    });
  });
}
