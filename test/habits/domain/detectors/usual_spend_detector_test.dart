import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/detectors/usual_spend_detector.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/habit_inputs.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/entities/usual_habit.dart';
import 'package:hisaab/habits/domain/entities/usual_spend.dart';
import 'package:hisaab/habits/domain/habit_index_builder.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

/// Mon 26 Oct 2026.
const CalendarDate _monday = CalendarDate(2026, 10, 26);

const Category _smoke = Category(
  id: 14,
  key: 'own_14',
  iconKey: 'other',
  kind: EntryKind.spent,
  sort: 9,
  customName: 'Smoke',
);

final List<Category> _categories = <Category>[...seedCategories, chai, _smoke];

const Option<UsualSpend> _none = Option<UsualSpend>.none();

final Option<UsualSpend> _chai20 = Option<UsualSpend>.of(UsualSpend(category: chai, amount: Money.fromMajor(20)));

UsualHabit _habit(
  Category category, {
  DayType dayType = DayType.weekday,
  TimeWindow window = const TimeWindow(startMinute: 585, lengthMinutes: 60),
  int rupees = 20,
  int hitDays = 18,
  int activeDays = 20,
  DateTime? lastHit,
  bool fading = false,
}) =>
    UsualHabit(
      categoryId: category.id,
      dayType: dayType,
      pooled: false,
      window: window,
      amount: Money.fromMajor(rupees),
      hitDays: hitDays,
      activeDays: activeDays,
      lastHit: lastHit ?? DateTime(2026, 10, 23, 10, 5),
      fading: fading,
    );

HabitIndex _index(
  List<UsualHabit> habits, {
  CalendarDate builtOn = _monday,
  Set<int> loggedToday = const <int>{},
  Map<int, SuggestionState> states = const <int, SuggestionState>{},
}) =>
    HabitIndex(builtOn: builtOn, habits: habits, loggedToday: loggedToday, states: states);

Option<UsualSpend> _suggest(HabitIndex index, DateTime now, {List<Category>? categories}) =>
    UsualSpendDetector.suggest(index, now: now, categories: categories ?? _categories);

void main() {
  group('UsualSpendDetector.suggest (BR-17 suggestion)', () {
    test('inside the window on a weekday: Chai ₹20', () {
      expect(_suggest(_index(<UsualHabit>[_habit(chai)]), DateTime(2026, 10, 26, 10, 5)), _chai20);
    });

    test("the worked example's index suggests Chai ₹20 at 10:05", () {
      final HabitIndex index = HabitIndexBuilder.build(
        HabitInputs(
          entries: chaiWeekdays(today: _monday),
          categories: _categories,
          states: const <int, SuggestionState>{},
        ),
        today: _monday,
      );

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _chai20);
    });

    test("at the window's first minute: yes; at its end minute: no", () {
      final HabitIndex index = _index(<UsualHabit>[_habit(chai)]);

      expect(_suggest(index, DateTime(2026, 10, 26, 9, 45)), _chai20);
      expect(_suggest(index, DateTime(2026, 10, 26, 9, 44, 59)), _none);
      expect(_suggest(index, DateTime(2026, 10, 26, 10, 44, 59)), _chai20);
      expect(_suggest(index, DateTime(2026, 10, 26, 10, 45)), _none);
    });

    test('outside the window: none', () {
      expect(_suggest(_index(<UsualHabit>[_habit(chai)]), DateTime(2026, 10, 26, 15, 30)), _none);
    });

    test('on Saturday: none', () {
      const CalendarDate saturday = CalendarDate(2026, 10, 31);

      expect(
        _suggest(_index(<UsualHabit>[_habit(chai)], builtOn: saturday), DateTime(2026, 10, 31, 10, 5)),
        _none,
      );
    });

    test('a weekend habit is offered on Saturday', () {
      const CalendarDate saturday = CalendarDate(2026, 10, 31);
      final HabitIndex index = _index(<UsualHabit>[_habit(chai, dayType: DayType.weekend)], builtOn: saturday);

      expect(_suggest(index, DateTime(2026, 10, 31, 10, 5)), _chai20);
    });

    test('the category already has an entry today: none (E65)', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(chai)], loggedToday: <int>{chai.id});

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _none);
    });

    test('a fading habit: none', () {
      expect(_suggest(_index(<UsualHabit>[_habit(chai, fading: true)]), DateTime(2026, 10, 26, 10, 5)), _none);
    });

    test('quiet today: none (E63)', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(chai)],
        states: <int, SuggestionState>{
          chai.id: SuggestionState(categoryId: chai.id, quietOn: const Option<CalendarDate>.of(_monday)),
        },
      );

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _none);
    });

    test('quiet yesterday: offered again', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(chai)],
        states: <int, SuggestionState>{
          chai.id: SuggestionState(
            categoryId: chai.id,
            quietOn: const Option<CalendarDate>.of(CalendarDate(2026, 10, 25)),
          ),
        },
      );

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _chai20);
    });

    test('resting: none (E63)', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(chai)],
        states: <int, SuggestionState>{
          chai.id: SuggestionState(
            categoryId: chai.id,
            restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 10, 26)),
          ),
        },
      );

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _none);
    });

    test("quiet for Chai still offers another category's habit in the same window", () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(chai), _habit(_smoke, rupees: 18, hitDays: 12)],
        states: <int, SuggestionState>{
          chai.id: SuggestionState(categoryId: chai.id, quietOn: const Option<CalendarDate>.of(_monday)),
        },
      );

      expect(
        _suggest(index, DateTime(2026, 10, 26, 10, 5)),
        Option<UsualSpend>.of(UsualSpend(category: _smoke, amount: Money.fromMajor(18))),
      );
    });

    test("the category is hidden in the tray's list: none (E59)", () {
      final HabitIndex index = _index(<UsualHabit>[_habit(chai)]);

      expect(
        _suggest(
          index,
          DateTime(2026, 10, 26, 10, 5),
          categories: <Category>[...seedCategories, chai.copyWith(hidden: true)],
        ),
        _none,
      );
    });

    test('the category is missing: none', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(chai)]);

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5), categories: seedCategories), _none);
    });

    test('an index built yesterday suggests nothing', () {
      final HabitIndex yesterdays = _index(<UsualHabit>[_habit(chai)]);

      expect(_suggest(yesterdays, DateTime(2026, 10, 27, 10, 5)), _none);
    });

    test('both sides of midnight (E58)', () {
      const TimeWindow lateNight = TimeWindow(startMinute: 1395, lengthMinutes: 90);
      final HabitIndex mondays = _index(<UsualHabit>[_habit(chai, window: lateNight)]);
      final HabitIndex tuesdays = _index(
        <UsualHabit>[_habit(chai, window: lateNight)],
        builtOn: const CalendarDate(2026, 10, 27),
      );

      expect(_suggest(mondays, DateTime(2026, 10, 26, 23, 20)), _chai20);
      expect(_suggest(tuesdays, DateTime(2026, 10, 27, 0, 10)), _chai20);
      expect(_suggest(tuesdays, DateTime(2026, 10, 27, 0, 45)), _none);
    });

    test('after midnight an entry logged before it no longer counts as today (E58)', () {
      const TimeWindow lateNight = TimeWindow(startMinute: 1395, lengthMinutes: 90);
      final HabitIndex mondays = _index(
        <UsualHabit>[_habit(chai, window: lateNight)],
        loggedToday: <int>{chai.id},
      );
      final HabitIndex tuesdays = _index(
        <UsualHabit>[_habit(chai, window: lateNight)],
        builtOn: const CalendarDate(2026, 10, 27),
      );

      expect(_suggest(mondays, DateTime(2026, 10, 26, 23, 50)), _none);
      expect(_suggest(tuesdays, DateTime(2026, 10, 27, 0, 10)), _chai20);
    });

    test('two qualify: the higher share of days wins (E61)', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(chai, hitDays: 18, activeDays: 20),
        _habit(_smoke, rupees: 18, hitDays: 10, activeDays: 10),
      ]);

      expect(
        _suggest(index, DateTime(2026, 10, 26, 10, 5)),
        Option<UsualSpend>.of(UsualSpend(category: _smoke, amount: Money.fromMajor(18))),
      );
    });

    test('equal share: the more recent hit (E61)', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(_smoke, rupees: 18, hitDays: 18, activeDays: 20, lastHit: DateTime(2026, 10, 22, 10, 5)),
        _habit(chai, hitDays: 9, activeDays: 10, lastHit: DateTime(2026, 10, 23, 10, 5)),
      ]);

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _chai20);
    });

    test('still equal: the lower category id', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(_smoke, rupees: 18), _habit(chai)]);

      expect(_suggest(index, DateTime(2026, 10, 26, 10, 5)), _chai20);
    });

    test('the label follows a rename', () {
      final Category renamed = chai.copyWith(customName: 'Cutting chai');

      final Option<UsualSpend> usual = _suggest(
        _index(<UsualHabit>[_habit(chai)]),
        DateTime(2026, 10, 26, 10, 5),
        categories: <Category>[...seedCategories, renamed],
      );

      expect(usual.map((UsualSpend spend) => spend.category.customName), const Option<String?>.of('Cutting chai'));
    });

    test('the amount at the 9-digit cap is suggested unchanged', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(chai, rupees: 999999999)]);

      expect(
        _suggest(index, DateTime(2026, 10, 26, 10, 5)),
        Option<UsualSpend>.of(UsualSpend(category: chai, amount: Money.fromMajor(999999999))),
      );
    });

    test('an empty index: none (E67)', () {
      expect(_suggest(HabitIndex.empty(_monday), DateTime(2026, 10, 26, 10, 5)), _none);
    });
  });

  group('UsualSpend', () {
    test('compares by its category and amount', () {
      expect(
        UsualSpend(category: chai, amount: Money.fromMajor(20)),
        UsualSpend(category: chai, amount: Money.fromMajor(20)),
      );
      expect(
        UsualSpend(category: chai, amount: Money.fromMajor(20)),
        isNot(UsualSpend(category: chai, amount: Money.fromMajor(30))),
      );
    });
  });
}
