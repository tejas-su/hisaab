import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/domain/month_story_rules.dart';

import 'categories.dart';

/// SPEC BR-20's worked example: September (Fri 4 Sep to Sat 3 Oct 2026) and the August before it.
abstract final class SeptemberStory {
  static const PayCycle september = PayCycle(start: CalendarDate(2026, 9, 4), end: CalendarDate(2026, 10, 3));
  static const PayCycle august = PayCycle(start: CalendarDate(2026, 8, 4), end: CalendarDate(2026, 9, 3));

  /// Day 2 of October: September is finished and the slim row still shows.
  static const CalendarDate today = CalendarDate(2026, 10, 5);

  static const int shopping = 3;
  static const int fun = 5;
  static const int health = 6;

  /// Everyday spending, one list per day of September (index 0 is Fri 4 Sep): `(rupees, category, note)`.
  static const List<List<(int, int, String?)>> everyday = <List<(int, int, String?)>>[
    <(int, int, String?)>[(620, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(1240, shopping, 'Kurta'), (600, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(450, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(980, SeedCategoryIds.travel, 'Petrol')],
    <(int, int, String?)>[(310, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(1260, fun, 'Movie')],
    <(int, int, String?)>[(3900, SeedCategoryIds.travel, 'Train tickets'), (950, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(1500, health, 'Doctor'), (600, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(540, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(720, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(1390, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(2600, shopping, 'Shoes')],
    <(int, int, String?)>[],
    <(int, int, String?)>[(380, SeedCategoryIds.travel, 'Auto')],
    <(int, int, String?)>[],
    <(int, int, String?)>[(1150, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(260, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(1480, fun, null)],
    <(int, int, String?)>[(2360, shopping, null), (840, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(690, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(360, fun, null), (480, SeedCategoryIds.food, null)],
    <(int, int, String?)>[],
    <(int, int, String?)>[(1190, SeedCategoryIds.food, null)],
    <(int, int, String?)>[(2040, SeedCategoryIds.travel, null), (1310, SeedCategoryIds.food, null)],
  ];

  /// Every September entry: pay, the RD, rent and electricity (posted by rules), and [everyday].
  static List<Entry> septemberEntries() {
    final List<Entry> entries = <Entry>[
      _entry(1, 45000, EntryKind.got, SeedCategoryIds.salary, september.start, recurringId: 1),
      _entry(2, 1000, EntryKind.saved, SeedCategoryIds.saved, september.start.addDays(1), recurringId: 2),
      _entry(3, 8200, EntryKind.spent, SeedCategoryIds.bills, september.start.addDays(1), recurringId: 3),
      _entry(4, 1200, EntryKind.spent, SeedCategoryIds.bills, september.start.addDays(25), recurringId: 4),
    ];
    for (final (int day, List<(int, int, String?)> spends) in everyday.indexed) {
      for (final (int rupees, int category, String? note) in spends) {
        entries.add(_entry(10 + entries.length, rupees, EntryKind.spent, category, september.start.addDays(day), note: note));
      }
    }
    return entries;
  }

  /// August: ₹47,100 spent, one entry per category.
  static List<Entry> augustEntries() => <Entry>[
        _entry(501, 45000, EntryKind.got, SeedCategoryIds.salary, august.start, recurringId: 1),
        _entry(502, 14300, EntryKind.spent, SeedCategoryIds.food, august.start.addDays(6)),
        _entry(503, 9400, EntryKind.spent, SeedCategoryIds.bills, august.start.addDays(1), recurringId: 3),
        _entry(504, 6100, EntryKind.spent, SeedCategoryIds.travel, august.start.addDays(6)),
        _entry(505, 10100, EntryKind.spent, shopping, august.start.addDays(6)),
        _entry(506, 4700, EntryKind.spent, fun, august.start.addDays(6)),
        _entry(507, 2500, EntryKind.spent, health, august.start.addDays(6)),
      ];

  /// BR-20's worked story; [entries] replaces September's, and [previousTracked] false drops page 5.
  static MonthStory story({List<Entry>? entries, bool previousTracked = true}) => MonthStoryRules.of(StoryWindow(
        cycle: september,
        previous: august,
        entries: entries ?? septemberEntries(),
        previousEntries: augustEntries(),
        previousTracked: previousTracked,
        categories: seedCategories,
      ));

  static Entry _entry(int id, int rupees, EntryKind kind, int categoryId, CalendarDate date, {int? recurringId, String? note}) => Entry(
        id: id,
        amount: Money.fromMajor(rupees),
        kind: kind,
        categoryId: categoryId,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 9),
        note: note,
        recurringId: recurringId,
      );
}
