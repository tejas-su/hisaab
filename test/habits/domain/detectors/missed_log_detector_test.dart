import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/detectors/missed_log_detector.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/missed_log.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/entities/usual_habit.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

/// Mon 26 Oct 2026.
const CalendarDate _monday = CalendarDate(2026, 10, 26);

/// Food's window: 12:15 to 2:00 pm, so the line first shows at 3:30 pm (BR-17 example).
const TimeWindow _foodWindow = TimeWindow(startMinute: 735, lengthMinutes: 105);

final List<Category> _categories = <Category>[...seedCategories, chai];

UsualHabit _habit(
  Category category, {
  DayType dayType = DayType.weekday,
  TimeWindow window = _foodWindow,
  int hitDays = 18,
  int activeDays = 20,
  DateTime? lastHit,
  bool fading = false,
  bool pooled = false,
}) =>
    UsualHabit(
      categoryId: category.id,
      dayType: dayType,
      pooled: pooled,
      window: window,
      amount: Money.fromMajor(55),
      hitDays: hitDays,
      activeDays: activeDays,
      lastHit: lastHit ?? DateTime(2026, 10, 23, 13),
      fading: fading,
    );

HabitIndex _index(
  List<UsualHabit> habits, {
  CalendarDate builtOn = _monday,
  Set<int> loggedToday = const <int>{},
  Map<int, SuggestionState> states = const <int, SuggestionState>{},
}) =>
    HabitIndex(builtOn: builtOn, habits: habits, loggedToday: loggedToday, states: states);

Option<MissedLog> _suggest(HabitIndex index, DateTime now, {List<Category>? categories}) =>
    MissedLogDetector.suggest(index, now: now, categories: categories ?? _categories);

/// Monday 26 Oct at [hour]:[minute].
DateTime _at(int hour, int minute) => DateTime(2026, 10, 26, hour, minute);

void main() {
  final HabitIndex foodIndex = _index(<UsualHabit>[_habit(food)]);

  group('MissedLogDetector.suggest (BR-17 missed-log line)', () {
    test("Food's window ends 2:00 pm: nothing at 1:50 pm and 3:29 pm, shown at 3:30 pm", () {
      expect(_suggest(foodIndex, _at(13, 50)), const Option<MissedLog>.none());
      expect(_suggest(foodIndex, _at(15, 29)), const Option<MissedLog>.none());
      expect(_suggest(foodIndex, _at(15, 29)).isNone(), isTrue);
      expect(
        _suggest(foodIndex, _at(15, 30)),
        Option<MissedLog>.of(MissedLog(category: food, window: _foodWindow, amount: Money.fromMajor(55))),
      );
      expect(_suggest(foodIndex, _at(23, 59)).isSome(), isTrue);
    });

    test('inside the window it never asks: the pill covers it (E103)', () {
      expect(_suggest(foodIndex, _at(12, 15)).isNone(), isTrue);
      expect(_suggest(foodIndex, _at(13, 59)).isNone(), isTrue);
    });

    test('a window across midnight never asks, at any time (E103)', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, window: const TimeWindow(startMinute: 1395, lengthMinutes: 90)),
      ]);

      for (final int hour in <int>[0, 1, 2, 12, 23]) {
        expect(_suggest(index, _at(hour, 59)).isNone(), isTrue);
      }
    });

    test('a window ending at 23:30 is never asked: its 90 minutes pass midnight', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, window: const TimeWindow(startMinute: 1350, lengthMinutes: 60)),
      ]);

      expect(_suggest(index, _at(23, 59)).isNone(), isTrue);
    });

    test('an entry in the category today, typed or posted, silences it (E65)', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(food)], loggedToday: <int>{food.id});

      expect(_suggest(index, _at(16, 0)).isNone(), isTrue);
    });

    test('an entry in another category does not', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(food)], loggedToday: <int>{chai.id});

      expect(_suggest(index, _at(16, 0)).isSome(), isTrue);
    });

    test('a fading habit is not asked', () {
      expect(_suggest(_index(<UsualHabit>[_habit(food, fading: true)]), _at(16, 0)).isNone(), isTrue);
    });

    test('a hidden category, or one not in the list, has no line (E59)', () {
      expect(
        _suggest(foodIndex, _at(16, 0), categories: <Category>[food.copyWith(hidden: true)]).isNone(),
        isTrue,
      );
      expect(_suggest(foodIndex, _at(16, 0), categories: <Category>[chai]).isNone(), isTrue);
    });

    test('quiet today and resting have no line; the day after a rest has one', () {
      SuggestionState resting(CalendarDate last) =>
          SuggestionState(categoryId: food.id, restUntil: Option<CalendarDate>.of(last));
      HabitIndex withState(SuggestionState state) =>
          _index(<UsualHabit>[_habit(food)], states: <int, SuggestionState>{food.id: state});

      final SuggestionState quiet = SuggestionState(categoryId: food.id, quietOn: const Option<CalendarDate>.of(_monday));

      expect(_suggest(withState(quiet), _at(16, 0)).isNone(), isTrue);
      expect(_suggest(withState(resting(_monday)), _at(16, 0)).isNone(), isTrue);
      expect(_suggest(withState(resting(_monday.addDays(-1))), _at(16, 0)).isSome(), isTrue);
    });

    test('one asked today, in any category, means no line for any (L3)', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(food)],
        states: <int, SuggestionState>{
          chai.id: const SuggestionState(categoryId: 13, askedOn: Option<CalendarDate>.of(_monday)),
        },
      );

      expect(_suggest(index, _at(16, 0)).isNone(), isTrue);
    });

    test('asked yesterday does not silence it', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(food)],
        states: <int, SuggestionState>{
          food.id: SuggestionState(categoryId: food.id, askedOn: Option<CalendarDate>.of(_monday.addDays(-1))),
        },
      );

      expect(_suggest(index, _at(16, 0)).isSome(), isTrue);
    });

    test('two qualify: the higher share of days wins, then the later hit, then the lower id', () {
      final UsualHabit lowShare = _habit(food, hitDays: 12);
      final UsualHabit highShare = _habit(chai, hitDays: 19);
      final UsualHabit earlierHit = _habit(chai, lastHit: DateTime(2026, 10, 20, 13));
      final UsualHabit laterHit = _habit(food, lastHit: DateTime(2026, 10, 23, 13));

      expect(_suggest(_index(<UsualHabit>[lowShare, highShare]), _at(16, 0)).map((MissedLog m) => m.category), Option<Category>.of(chai));
      expect(_suggest(_index(<UsualHabit>[earlierHit, laterHit]), _at(16, 0)).map((MissedLog m) => m.category), Option<Category>.of(food));
      expect(_suggest(_index(<UsualHabit>[_habit(chai), _habit(food)]), _at(16, 0)).map((MissedLog m) => m.category), Option<Category>.of(food));
    });

    test('a candidate that is not yet 90 minutes past its window loses to one that is', () {
      final UsualHabit late = _habit(chai, window: const TimeWindow(startMinute: 900, lengthMinutes: 60));

      expect(_suggest(_index(<UsualHabit>[late, _habit(food)]), _at(16, 0)).map((MissedLog m) => m.category), Option<Category>.of(food));
    });

    test('a weekend habit is not asked on a weekday, and the reverse', () {
      const CalendarDate saturday = CalendarDate(2026, 10, 31);

      expect(_suggest(_index(<UsualHabit>[_habit(food, dayType: DayType.weekend)]), _at(16, 0)).isNone(), isTrue);
      expect(
        _suggest(_index(<UsualHabit>[_habit(food)], builtOn: saturday), DateTime(2026, 10, 31, 16)).isNone(),
        isTrue,
      );
      expect(
        _suggest(_index(<UsualHabit>[_habit(food, dayType: DayType.weekend)], builtOn: saturday), DateTime(2026, 10, 31, 16)).isSome(),
        isTrue,
      );
    });

    test('a pooled habit is asked on the day type it is offered on (E64)', () {
      expect(_suggest(_index(<UsualHabit>[_habit(food, pooled: true)]), _at(16, 0)).isSome(), isTrue);
    });

    test('a stale index, built yesterday, returns none (M18)', () {
      expect(_suggest(_index(<UsualHabit>[_habit(food)], builtOn: _monday.addDays(-1)), _at(16, 0)).isNone(), isTrue);
    });

    test('an empty index returns none', () {
      expect(_suggest(HabitIndex.empty(_monday), _at(16, 0)).isNone(), isTrue);
    });

    test('around is the window middle, a half hour rounding up (BR-17)', () {
      final MissedLog food1pm = _suggest(foodIndex, _at(16, 0)).toNullable()!;
      final MissedLog half = _suggest(
        _index(<UsualHabit>[_habit(food, window: const TimeWindow(startMinute: 600, lengthMinutes: 60))]),
        _at(16, 0),
      ).toNullable()!;

      expect(food1pm.aroundHour, 13);
      expect(half.aroundHour, 11);
    });

    test('the detector reads nothing else: the same index gives the same answer all day (D189)', () {
      expect(_suggest(foodIndex, _at(15, 30)), _suggest(foodIndex, _at(21, 0)));
    });
  });

  group('MissedLog', () {
    test('compares by category, window and amount', () {
      final MissedLog a = MissedLog(category: food, window: _foodWindow, amount: Money.fromMajor(55));

      expect(a, MissedLog(category: food, window: _foodWindow, amount: Money.fromMajor(55)));
      expect(a, isNot(MissedLog(category: food, window: _foodWindow, amount: Money.fromMajor(56))));
    });
  });
}
