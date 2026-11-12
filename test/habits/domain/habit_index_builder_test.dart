import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/habit_inputs.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/entities/usual_habit.dart';
import 'package:hisaab/habits/domain/habit_index_builder.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';

import '../../helpers/fixtures/habits/chai_habit.dart';
import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

/// Mon 26 Oct 2026.
const CalendarDate _today = WorkedExample.today;

/// 9:45–10:45, the window of entries logged at 10:05.
const TimeWindow _morning = TimeWindow(startMinute: 585, lengthMinutes: 60);

final List<Category> _categories = <Category>[...seedCategories, chai];

/// The 20 weekdays of 28 Sep – 23 Oct 2026, oldest first: index 0 is Mon 28 Sep, 19 is Fri 23 Oct.
final List<CalendarDate> _weekdays = daysBefore(_today, DayType.weekday);

/// The 8 weekend days of 3 – 25 Oct 2026, oldest first: 3, 4, 10, 11, 17, 18, 24, 25 Oct.
final List<CalendarDate> _weekends = daysBefore(_today, DayType.weekend);

HabitIndex _build(
  List<Entry> entries, {
  List<Category>? categories,
  Map<int, SuggestionState> states = const <int, SuggestionState>{},
  CalendarDate today = _today,
}) =>
    HabitIndexBuilder.build(
      HabitInputs(entries: entries, categories: categories ?? _categories, states: states),
      today: today,
    );

List<UsualHabit> _chaiHabits(HabitIndex index, DayType type) => index.habits
    .where((UsualHabit habit) => habit.categoryId == chai.id && habit.dayType == type)
    .toList();

Entry _withAmount(Entry entry, Money amount) => Entry(
      id: entry.id,
      amount: amount,
      kind: entry.kind,
      categoryId: entry.categoryId,
      date: entry.date,
      createdAt: entry.createdAt,
    );

/// Enough Food for the warm-up, plus Chai at 10:05 on Tue 20 – Fri 23 Oct: one entry short of a habit.
List<Entry> _fourHits() => <Entry>[...warmUpFood(_today), ...entriesOn(_weekdays.skip(16), chai, firstId: 201)];

/// Chai on all 20 weekdays: ₹20 on Mondays, Wednesdays and Fridays, ₹30 on Tuesdays and Thursdays.
List<Entry> _twoAmounts() => <Entry>[
      ...entriesOn(_weekdays.where((CalendarDate date) => date.weekday.isOdd), chai, firstId: 201),
      ...entriesOn(_weekdays.where((CalendarDate date) => date.weekday.isEven), chai, rupees: 30, firstId: 301),
    ];

void main() {
  group('HabitIndexBuilder.build learns from (BR-17)', () {
    test('the worked example makes one weekday habit: Chai ₹20, 9:45–10:45, 18 of 20', () {
      final HabitIndex index = _build(chaiWeekdays(today: _today));

      expect(index.habits, <UsualHabit>[
        UsualHabit(
          categoryId: chai.id,
          dayType: DayType.weekday,
          pooled: false,
          window: _morning,
          amount: Money.fromMajor(20),
          hitDays: 18,
          activeDays: 20,
          lastHit: DateTime(2026, 10, 23, 10, 5),
          fading: false,
        ),
      ]);
      expect(index.builtOn, _today);
    });

    test('an entry posted by a rule is ignored', () {
      final HabitIndex index = _build(<Entry>[
        ..._fourHits(),
        entryAt(900, chai, 20, DateTime(2026, 10, 19, 10, 5), recurringId: 7),
      ]);

      expect(index.habits, isEmpty);
    });

    test('a back-dated entry is ignored (E60)', () {
      final HabitIndex index = _build(<Entry>[
        ..._fourHits(),
        entryAt(900, chai, 20, DateTime(2026, 10, 19, 10, 5), date: const CalendarDate(2026, 10, 16)),
      ]);

      expect(index.habits, isEmpty);
    });

    test('Got and Saved entries are ignored', () {
      final HabitIndex index = _build(<Entry>[
        ..._fourHits(),
        entryAt(900, chai, 20, DateTime(2026, 10, 19, 10, 5), kind: EntryKind.got),
        entryAt(901, chai, 20, DateTime(2026, 10, 16, 10, 5), kind: EntryKind.saved),
        entryAt(902, chai, 20, DateTime(2026, 10, 15, 10, 5), kind: EntryKind.cardPaid),
      ]);

      expect(index.habits, isEmpty);
    });

    test('an entry 56 days old is ignored', () {
      final HabitIndex index = _build(<Entry>[
        ..._fourHits(),
        entryAt(900, chai, 20, DateTime(2026, 8, 31, 10, 5)),
      ]);

      expect(index.habits, isEmpty);
    });

    test('an entry 55 days old counts', () {
      final HabitIndex index = _build(<Entry>[
        ..._fourHits(),
        entryAt(900, chai, 20, DateTime(2026, 9, 1, 10, 5)),
      ]);

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
    });

    test('an entry dated after today is ignored (E66)', () {
      final HabitIndex index = _build(<Entry>[
        ..._fourHits(),
        entryAt(900, chai, 20, DateTime(2026, 10, 27, 10, 5)),
      ]);

      expect(index.habits, isEmpty);
    });

    test('an edit to another category counts in the new category (E60)', () {
      final Entry movedToFood = entryAt(900, food, 20, DateTime(2026, 10, 19, 10, 5));
      final Entry movedToChai = entryAt(900, chai, 20, DateTime(2026, 10, 19, 10, 5));

      expect(_build(<Entry>[..._fourHits(), movedToFood]).habits, isEmpty);
      expect(_chaiHabits(_build(<Entry>[..._fourHits(), movedToChai]), DayType.weekday), hasLength(1));
    });

    test('an edit to another amount counts with the new amount (E60)', () {
      final HabitIndex index = _build(<Entry>[
        ...warmUpFood(_today),
        ...entriesOn(_weekdays.skip(15), chai, rupees: 25, firstId: 201),
      ]);

      expect(_chaiHabits(index, DayType.weekday).single.amount, Money.fromMajor(25));
    });

    test('a hidden category has no habit; shown again, it has (E59)', () {
      final List<Entry> entries = chaiWeekdays(today: _today);
      final Category hiddenChai = chai.copyWith(hidden: true);

      final HabitIndex hidden = _build(entries, categories: <Category>[...seedCategories, hiddenChai]);
      final HabitIndex shown = _build(
        entries,
        categories: <Category>[...seedCategories, hiddenChai.copyWith(hidden: false)],
      );

      expect(hidden.habits, isEmpty);
      expect(_chaiHabits(shown, DayType.weekday), hasLength(1));
    });

    test("a hidden category's entries still make their days active for other habits", () {
      final HabitIndex index = _build(
        chaiWeekdays(today: _today),
        categories: <Category>[food.copyWith(hidden: true), chai],
      );

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.hitDays, 18);
      expect(habit.activeDays, 20);
    });

    test('a hidden category keeps its quiet state when it is shown again (E69)', () {
      final Map<int, SuggestionState> states = <int, SuggestionState>{
        chai.id: SuggestionState(categoryId: chai.id, quietOn: const Option<CalendarDate>.of(_today)),
      };

      final HabitIndex index = _build(
        chaiWeekdays(today: _today),
        categories: <Category>[...seedCategories, chai.copyWith(hidden: true)],
        states: states,
      );

      expect(index.states, states);
    });

    test('the saved and card_paid rows have none', () {
      const Category savedRow = Category(id: 11, key: 'saved', iconKey: 'other', kind: EntryKind.spent, sort: 0);
      const Category cardRow = Category(id: 12, key: 'card_paid', iconKey: 'other', kind: EntryKind.spent, sort: 0);

      final HabitIndex index = _build(<Entry>[
        ...warmUpFood(_today),
        ...entriesOn(_weekdays, savedRow, firstId: 201),
        ...entriesOn(_weekdays, cardRow, firstId: 301),
      ]);

      expect(index.habits, isEmpty);
    });

    test('a Got category has none', () {
      final Category salary = seedCategories[8];

      final HabitIndex index = _build(<Entry>[
        ...warmUpFood(_today),
        ...entriesOn(_weekdays, salary, firstId: 201),
      ]);

      expect(index.habits, isEmpty);
    });

    test('entries before Forget are ignored; later ones count', () {
      final HabitIndex index = _build(
        chaiWeekdays(today: _today, misses: 0),
        states: <int, SuggestionState>{
          chai.id: SuggestionState(
            categoryId: chai.id,
            forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 6, 10, 6)),
          ),
        },
      );

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.hitDays, 13, reason: 'Wed 7 – Fri 23 Oct; Tue 6 Oct was logged a minute before Forget');
      expect(habit.activeDays, 20);
    });

    test('an entry logged at the moment of Forget counts', () {
      final HabitIndex index = _build(
        chaiWeekdays(today: _today, misses: 0),
        states: <int, SuggestionState>{
          chai.id: SuggestionState(
            categoryId: chai.id,
            forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 6, 10, 5)),
          ),
        },
      );

      expect(_chaiHabits(index, DayType.weekday).single.hitDays, 14);
    });

    test('a category forgotten today has no habit', () {
      final HabitIndex index = _build(
        chaiWeekdays(today: _today),
        states: <int, SuggestionState>{
          chai.id: SuggestionState(
            categoryId: chai.id,
            forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 9)),
          ),
        },
      );

      expect(index.habits, isEmpty);
    });

    test('forgotten entries still make their days active for other habits, and the warm-up holds', () {
      final HabitIndex index = _build(
        <Entry>[
          ...foodOn(List<CalendarDate>.generate(10, (int day) => const CalendarDate(2026, 9, 25).addDays(day))),
          ...entriesOn(_weekdays.skip(11), chai, firstId: 201),
        ],
        states: <int, SuggestionState>{
          food.id: SuggestionState(
            categoryId: food.id,
            forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 9)),
          ),
        },
      );

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.hitDays, 9);
      expect(habit.activeDays, 14);
    });

    test('an empty ledger is an empty index (E67)', () {
      expect(_build(<Entry>[]), HabitIndex.empty(_today));
    });
  });

  group('HabitIndexBuilder.build rule 1, the warm-up (BR-17)', () {
    test('13 days after the first entry: nothing (E67)', () {
      final HabitIndex index = _build(<Entry>[
        ...entriesOn(_weekdays.skip(11), chai, firstId: 201),
        entryAt(900, chai, 20, DateTime(2026, 10, 26, 10, 5)),
      ]);

      expect(index.habits, isEmpty);
    });

    test('14 days with 10 active days: a habit', () {
      final HabitIndex index = _build(entriesOn(_weekdays.skip(10), chai, firstId: 201));

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
    });

    test('14 days with 9 active days: nothing', () {
      final HabitIndex index = _build(entriesOn(_weekdays.skip(10).take(9), chai, firstId: 201));

      expect(index.habits, isEmpty);
    });

    test('the warm-up is app-wide: a category first used 13 days ago can be Regular', () {
      final HabitIndex index = _build(<Entry>[
        ...foodOn(List<CalendarDate>.generate(10, (int day) => const CalendarDate(2026, 9, 25).addDays(day))),
        ...entriesOn(_weekdays.skip(11), chai, firstId: 201),
      ]);

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.hitDays, 9);
      expect(habit.activeDays, 14);
    });
  });

  group('HabitIndexBuilder.build rule 2, entries in the window (BR-17)', () {
    test('4 entries in the window: nothing', () {
      expect(_build(_fourHits()).habits, isEmpty);
    });

    test('5: a habit', () {
      final HabitIndex index = _build(<Entry>[
        ...warmUpFood(_today),
        ...entriesOn(_weekdays.skip(15), chai, firstId: 201),
      ]);

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
    });

    test('an entry 10 minutes before the first slot is a hit', () {
      final HabitIndex index = _build(<Entry>[
        ...warmUpFood(_today),
        entryAt(200, chai, 20, DateTime(2026, 9, 28, 9, 50)),
        ...entriesOn(<CalendarDate>[_weekdays[16], _weekdays[17]], chai, minute: 35, firstId: 201),
        ...entriesOn(<CalendarDate>[_weekdays[18], _weekdays[19]], chai, firstId: 203),
      ]);

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(
        habit.window,
        const TimeWindow(startMinute: 585, lengthMinutes: 90),
        reason: 'the 10:00 and 10:30 slots, widened; the 9:30 slot is not in the run',
      );
      expect(habit.hitDays, 5);
    });
  });

  group('HabitIndexBuilder.build rule 3, the share of days (BR-17)', () {
    test('12 of 20 active weekdays: a habit', () {
      final UsualHabit habit =
          _chaiHabits(_build(chaiWeekdays(today: _today, misses: 8)), DayType.weekday).single;

      expect(habit.hitDays, 12);
      expect(habit.activeDays, 20);
    });

    test('11 of 20: nothing', () {
      expect(_build(chaiWeekdays(today: _today, misses: 9)).habits, isEmpty);
    });

    test('a day with no entry at all is not in the share', () {
      final List<Entry> entries = chaiWeekdays(today: _today, misses: 9)
          .where((Entry entry) => entry.date != _weekdays[0] && entry.date != _weekdays[1])
          .toList();

      final UsualHabit habit = _chaiHabits(_build(entries), DayType.weekday).single;
      expect(habit.hitDays, 11);
      expect(habit.activeDays, 18);
    });

    test('another entry today does not change the share', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today, misses: 8),
        entryAt(900, food, 60, DateTime(2026, 10, 26, 8, 30)),
      ]);

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.hitDays, 12);
      expect(habit.activeDays, 20);
    });

    test('two hits on one day are one hit day', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today),
        entryAt(900, chai, 20, DateTime(2026, 10, 23, 10, 10)),
      ]);

      expect(_chaiHabits(index, DayType.weekday).single.hitDays, 18);
    });
  });

  group('HabitIndexBuilder.build rule 4, the amount (BR-17)', () {
    test('the suggested amount is the one logged, to the paise', () {
      final HabitIndex index = _build(<Entry>[
        ...warmUpFood(_today),
        ...entriesOn(_weekdays.skip(15), chai, firstId: 201).map((Entry entry) => _withAmount(entry, const Money(2050))),
      ]);

      expect(_chaiHabits(index, DayType.weekday).single.amount, const Money(2050));
    });

    test('two amounts at 60/40: nothing', () {
      expect(_build(<Entry>[...foodDays(_today), ..._twoAmounts()]).habits, isEmpty);
    });
  });

  group('HabitIndexBuilder.build day types (BR-17)', () {
    test('weekdays and weekends are learned apart', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today, misses: 0),
        ...entriesOn(_weekends, chai, hour: 16, minute: 0, firstId: 401),
      ]);

      final UsualHabit weekday = _chaiHabits(index, DayType.weekday).single;
      final UsualHabit weekend = _chaiHabits(index, DayType.weekend).single;
      expect(weekday.window, _morning);
      expect(weekday.pooled, isFalse);
      expect(weekend.window, const TimeWindow(startMinute: 945, lengthMinutes: 60));
      expect(weekend.pooled, isFalse);
      expect(weekend.hitDays, 8);
      expect(weekend.activeDays, 8);
    });

    test(
        'weekdays Regular, weekends with 3 entries, 2 of them in the pooled window: '
        'weekends use the pooled habit (E64)', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today),
        ...entriesOn(<CalendarDate>[_weekends[4], _weekends[6]], chai, firstId: 401),
        ...entriesOn(<CalendarDate>[_weekends[5]], chai, hour: 16, minute: 0, firstId: 403),
      ]);

      expect(_chaiHabits(index, DayType.weekday).single.pooled, isFalse);
      expect(_chaiHabits(index, DayType.weekend), <UsualHabit>[
        UsualHabit(
          categoryId: chai.id,
          dayType: DayType.weekend,
          pooled: true,
          window: _morning,
          amount: Money.fromMajor(20),
          hitDays: 20,
          activeDays: 26,
          lastHit: DateTime(2026, 10, 24, 10, 5),
          fading: false,
        ),
      ]);
    });

    test('with 1 weekend entry in the pooled window: nothing on weekends (E64)', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today),
        ...entriesOn(<CalendarDate>[_weekends[4]], chai, firstId: 401),
        ...entriesOn(<CalendarDate>[_weekends[5], _weekends[6]], chai, hour: 16, minute: 0, firstId: 402),
      ]);

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
      expect(_chaiHabits(index, DayType.weekend), isEmpty);
    });

    test('2 weekend entries in the pooled window but older than 28 days: nothing on weekends', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today),
        ...entriesOn(const <CalendarDate>[CalendarDate(2026, 9, 26), CalendarDate(2026, 9, 27)], chai, firstId: 401),
      ]);

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
      expect(_chaiHabits(index, DayType.weekend), isEmpty);
    });

    test('a strong weekday habit with no weekend hits is silent on Saturday', () {
      final HabitIndex index = _build(chaiWeekdays(today: _today, misses: 0));

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
      expect(_chaiHabits(index, DayType.weekend), isEmpty);
    });

    test('a weekend that fails rule 4 gets no pooled habit', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today),
        ...entriesOn(<CalendarDate>[_weekends[4]], chai, firstId: 401),
        ...entriesOn(<CalendarDate>[_weekends[6]], chai, rupees: 50, firstId: 402),
      ]);

      expect(_chaiHabits(index, DayType.weekday), hasLength(1));
      expect(_chaiHabits(index, DayType.weekend), isEmpty);
    });

    test('pooled passes only when it passes all four', () {
      final HabitIndex index = _build(<Entry>[
        ...foodDays(_today),
        ..._twoAmounts(),
        ...entriesOn(<CalendarDate>[_weekends[4], _weekends[6]], chai, firstId: 401),
      ]);

      expect(index.habits, isEmpty);
    });
  });

  group('HabitIndexBuilder.build missed 3 in a row (BR-17)', () {
    test('missed on the last 3 active weekdays: fading', () {
      final HabitIndex index = _build(<Entry>[
        ...foodDays(_today),
        ...entriesOn(_weekdays.take(17), chai, firstId: 201),
      ]);

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.fading, isTrue);
      expect(habit.hitDays, 17);
    });

    test('missed on 2: not fading', () {
      final HabitIndex index = _build(<Entry>[
        ...foodDays(_today),
        ...entriesOn(_weekdays.take(18), chai, firstId: 201),
      ]);

      expect(_chaiHabits(index, DayType.weekday).single.fading, isFalse);
    });

    test('a hit after 3 misses: not fading', () {
      final HabitIndex index = _build(<Entry>[
        ...foodDays(_today),
        ...entriesOn(<CalendarDate>[..._weekdays.take(16), _weekdays[19]], chai, firstId: 201),
      ]);

      expect(_chaiHabits(index, DayType.weekday).single.fading, isFalse);
    });

    test('days with no entry are not misses', () {
      final List<Entry> entries = <Entry>[
        ...foodDays(_today).where((Entry entry) => entry.date != _weekdays[18] && entry.date != _weekdays[19]),
        ...entriesOn(_weekdays.take(17), chai, firstId: 201),
      ];

      final UsualHabit habit = _chaiHabits(_build(entries), DayType.weekday).single;
      expect(habit.fading, isFalse);
      expect(habit.activeDays, 18);
    });

    test('a pooled habit on weekends fades on 3 missed weekend days, whatever the weekdays did', () {
      final HabitIndex index = _build(<Entry>[
        ...chaiWeekdays(today: _today),
        ...entriesOn(<CalendarDate>[_weekends[0], _weekends[1]], chai, firstId: 401),
        ...foodOn(<CalendarDate>[_weekends[4], _weekends[6]], firstId: 501),
      ]);

      final UsualHabit weekend = _chaiHabits(index, DayType.weekend).single;
      expect(weekend.pooled, isTrue);
      expect(weekend.fading, isTrue);
      expect(_chaiHabits(index, DayType.weekday).single.fading, isFalse);
    });
  });

  group('HabitIndexBuilder.build dates (BR-17)', () {
    test('a window across midnight (E58)', () {
      final HabitIndex index = _build(<Entry>[
        ...foodDays(_today),
        ...entriesOn(_weekdays.where((CalendarDate date) => date.weekday.isOdd), chai,
            hour: 23, minute: 40, firstId: 201),
        ...entriesOn(_weekdays.where((CalendarDate date) => date.weekday.isEven), chai,
            hour: 0, minute: 20, firstId: 301),
      ]);

      final UsualHabit habit = _chaiHabits(index, DayType.weekday).single;
      expect(habit.window, const TimeWindow(startMinute: 1395, lengthMinutes: 90));
      expect(habit.hitDays, 20);
    });

    final List<(String, CalendarDate, DateTime)> horizons = <(String, CalendarDate, DateTime)>[
      ('a horizon across 29 February 2028', const CalendarDate(2028, 3, 10), DateTime(2028, 3, 9, 10, 5)),
      ('across New Year', const CalendarDate(2027, 1, 10), DateTime(2027, 1, 8, 10, 5)),
    ];
    for (final (String name, CalendarDate today, DateTime lastHit) in horizons) {
      test('$name: the same habit as the October fixture (E70)', () {
        final HabitIndex index = _build(chaiWeekdays(today: today), today: today);

        expect(index.habits, <UsualHabit>[
          UsualHabit(
            categoryId: chai.id,
            dayType: DayType.weekday,
            pooled: false,
            window: _morning,
            amount: Money.fromMajor(20),
            hitDays: 18,
            activeDays: 20,
            lastHit: lastHit,
            fading: false,
          ),
        ]);
      });
    }
  });

  group('HabitIndexBuilder.build index', () {
    test('loggedToday holds every category with an entry dated today, typed or posted (E65)', () {
      final Category salary = seedCategories[8];

      final HabitIndex index = _build(<Entry>[
        entryAt(1, food, 60, DateTime(2026, 10, 26, 8, 30)),
        entryAt(2, salary, 45000, DateTime(2026, 10, 26, 0, 1), kind: EntryKind.got, recurringId: 1),
        entryAt(3, chai, 20, DateTime(2026, 10, 25, 10, 5)),
        entryAt(4, seedCategories[1], 120, DateTime(2026, 10, 27, 9), date: _today),
      ]);

      expect(index.loggedToday, <int>{food.id, salary.id, seedCategories[1].id});
    });

    test('loggedToday is filled before the warm-up is over', () {
      final HabitIndex index = _build(<Entry>[entryAt(1, chai, 20, DateTime(2026, 10, 26, 10, 5))]);

      expect(index.habits, isEmpty);
      expect(index.loggedToday, <int>{chai.id});
    });
  });
}
