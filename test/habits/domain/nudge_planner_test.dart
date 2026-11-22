import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/nudge.dart';
import 'package:hisaab/habits/domain/entities/nudge_state.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/entities/usual_habit.dart';
import 'package:hisaab/habits/domain/nudge_planner.dart';
import 'package:hisaab/habits/domain/nudge_rules.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';

import '../../helpers/fakes/fake_clock.dart';
import '../../helpers/fixtures/habits/chai_habit.dart';
import '../../helpers/fixtures/ledger/categories.dart';

/// Mon 26 Oct 2026.
const CalendarDate _monday = CalendarDate(2026, 10, 26);

/// Food's window: 12:15 to 2:00 pm, so its nudge is armed for 3:30 pm (BR-22 example).
const TimeWindow _foodWindow = TimeWindow(startMinute: 735, lengthMinutes: 105);

final List<Category> _categories = <Category>[...seedCategories, chai];

UsualHabit _habit(
  Category category, {
  DayType dayType = DayType.weekday,
  TimeWindow window = _foodWindow,
  int hitDays = 18,
  int activeDays = 20,
  bool fading = false,
}) =>
    UsualHabit(
      categoryId: category.id,
      dayType: dayType,
      pooled: false,
      window: window,
      amount: Money.fromMajor(55),
      hitDays: hitDays,
      activeDays: activeDays,
      lastHit: DateTime(2026, 10, 23, 13),
      fading: fading,
    );

HabitIndex _index(
  List<UsualHabit> habits, {
  CalendarDate builtOn = _monday,
  Set<int> loggedToday = const <int>{},
  Map<int, SuggestionState> states = const <int, SuggestionState>{},
}) =>
    HabitIndex(builtOn: builtOn, habits: habits, loggedToday: loggedToday, states: states);

/// The planner at the instant a [FakeClock] says, as the arming code would call it.
List<Nudge> _plan(
  HabitIndex index, {
  DateTime? now,
  List<Category>? categories,
  Map<int, NudgeState> nudgeStates = const <int, NudgeState>{},
  bool hasEnoughDays = true,
}) =>
    NudgePlanner.plan(
      index,
      now: FakeClock(now ?? DateTime(2026, 10, 26, 9)).now(),
      categories: categories ?? _categories,
      nudgeStates: nudgeStates,
      hasEnoughDays: hasEnoughDays,
    );

Nudge _nudge(CalendarDate date, int? categoryId, int hour, int minute) => Nudge(
      date: date,
      categoryId: Option<int>.fromNullable(categoryId),
      at: DateTime(date.year, date.month, date.day, hour, minute),
    );

NudgeState _rest(int categoryId, CalendarDate last) =>
    NudgeState(categoryId: categoryId, restUntil: Option<CalendarDate>.of(last));

void main() {
  final CalendarDate tuesday = _monday.addDays(1);
  final HabitIndex foodIndex = _index(<UsualHabit>[_habit(food)]);

  group('NudgePlanner.plan: candidate (BR-22.1)', () {
    test('window ends 14:00: armed for 15:30 on the same date, today and tomorrow', () {
      expect(_plan(foodIndex), <Nudge>[_nudge(_monday, 1, 15, 30), _nudge(tuesday, 1, 15, 30)]);
    });

    test('window ends 21:30: 23:00 is after 22:00, so no nudge (E123)', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, window: const TimeWindow(startMinute: 1200, lengthMinutes: 90)),
      ]);
      expect(_plan(index), isEmpty);
    });

    test('window ends 20:30: 22:00 exactly still shows', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, window: const TimeWindow(startMinute: 1170, lengthMinutes: 60)),
      ]);
      expect(_plan(index).first, _nudge(_monday, 1, 22, 0));
    });

    test('window crossing midnight (23:15 to 00:45): no nudge (E123)', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, window: const TimeWindow(startMinute: 1395, lengthMinutes: 90)),
      ]);
      expect(_plan(index), isEmpty);
    });

    test('a fading habit, a hidden category and an index of another day give none', () {
      expect(_plan(_index(<UsualHabit>[_habit(food, fading: true)])), isEmpty);
      final List<Category> hidden = <Category>[
        for (final Category category in _categories) category.id == 1 ? category.copyWith(hidden: true) : category,
      ];
      expect(_plan(foodIndex, categories: hidden), isEmpty);
      expect(_plan(_index(<UsualHabit>[_habit(food)], builtOn: _monday.addDays(-1))), isEmpty);
    });

    test('the category was logged today: no nudge today, tomorrow is still planned', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(food)], loggedToday: <int>{1});
      expect(_plan(index), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
    });

    test('undone from the pill today (quiet): none today, tomorrow still planned', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(food)],
        states: <int, SuggestionState>{1: SuggestionState(categoryId: 1, quietOn: Option<CalendarDate>.of(_monday))},
      );
      expect(_plan(index), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
    });

    test('a BR-17 rest from Forget or two Undos covers the days it lasts', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(food)],
        states: <int, SuggestionState>{1: SuggestionState(categoryId: 1, restUntil: Option<CalendarDate>.of(_monday))},
      );
      expect(_plan(index), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
    });

    test('the habit of the other day type is not used: a weekend habit on Saturday, not Friday', () {
      final HabitIndex friday = _index(
        <UsualHabit>[_habit(food, dayType: DayType.weekend)],
        builtOn: const CalendarDate(2026, 10, 30),
      );
      expect(_plan(friday, now: DateTime(2026, 10, 30, 9)), <Nudge>[_nudge(const CalendarDate(2026, 10, 31), 1, 15, 30)]);
    });

    test("tomorrow uses tomorrow's day type: Sunday's tomorrow is a weekday", () {
      final HabitIndex sunday = _index(<UsualHabit>[_habit(food)], builtOn: const CalendarDate(2026, 11, 1));
      expect(_plan(sunday, now: DateTime(2026, 11, 1, 9)), <Nudge>[_nudge(const CalendarDate(2026, 11, 2), 1, 15, 30)]);
    });

    test('two habits qualify: one nudge a date, the pill tie-break picks it (higher share first)', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, hitDays: 12),
        _habit(chai, hitDays: 19, window: const TimeWindow(startMinute: 540, lengthMinutes: 60)),
      ]);
      expect(_plan(index), <Nudge>[_nudge(_monday, 13, 11, 30), _nudge(tuesday, 13, 11, 30)]);
    });

    test('a resting category lets the other habit take the date', () {
      final HabitIndex index = _index(<UsualHabit>[
        _habit(food, hitDays: 12),
        _habit(chai, hitDays: 19, window: const TimeWindow(startMinute: 540, lengthMinutes: 60)),
      ]);
      final List<Nudge> plan = _plan(index, nudgeStates: <int, NudgeState>{13: _rest(13, tuesday)});
      expect(plan, <Nudge>[_nudge(_monday, 1, 15, 30), _nudge(tuesday, 1, 15, 30)]);
    });
  });

  group('NudgePlanner.plan: armed ahead (BR-22.3)', () {
    test('now after its time: today is skipped, tomorrow is kept', () {
      expect(_plan(foodIndex, now: DateTime(2026, 10, 26, 15, 31)), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
    });

    test('now 31 Dec 2026 evening: today is past, tomorrow is 1 Jan 2027 at 15:30 (year crossing)', () {
      final HabitIndex newYearsEve = _index(<UsualHabit>[_habit(food)], builtOn: const CalendarDate(2026, 12, 31));
      expect(_plan(newYearsEve, now: DateTime(2026, 12, 31, 21)), <Nudge>[_nudge(const CalendarDate(2027, 1, 1), 1, 15, 30)]);
    });

    test("now 31 Dec 2027 evening: tomorrow's day type is used, so a weekend habit plans only Sat 1 Jan 2028", () {
      final HabitIndex newYearsEve = _index(
        <UsualHabit>[_habit(food, dayType: DayType.weekend)],
        builtOn: const CalendarDate(2027, 12, 31),
      );
      expect(_plan(newYearsEve, now: DateTime(2027, 12, 31, 9)), <Nudge>[_nudge(const CalendarDate(2028, 1, 1), 1, 15, 30)]);
    });

    test('now exactly at its time: today is skipped (strictly after)', () {
      expect(_plan(foodIndex, now: DateTime(2026, 10, 26, 15, 30)), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
      expect(_plan(foodIndex, now: DateTime(2026, 10, 26, 15, 29)).length, 2);
    });

    test('tomorrow ignores what describes today: logged today and asked today', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(food)],
        loggedToday: <int>{1},
        states: <int, SuggestionState>{1: SuggestionState(categoryId: 1, askedOn: Option<CalendarDate>.of(_monday))},
      );
      expect(_plan(index), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
    });

    test('the nudge ids of today and tomorrow differ, and arming again gives the same ids', () {
      final List<int> first = _plan(foodIndex).map((Nudge nudge) => nudge.id).toList();
      final List<int> again = _plan(foodIndex).map((Nudge nudge) => nudge.id).toList();
      expect(first, again);
      expect(first.toSet().length, 2);
    });
  });

  group('NudgePlanner.plan: cancelled (BR-22.4)', () {
    test('the missed-log line was asked today (asked_on = today): none today, tomorrow planned', () {
      final HabitIndex index = _index(
        <UsualHabit>[_habit(food)],
        states: <int, SuggestionState>{1: SuggestionState(categoryId: 1, askedOn: Option<CalendarDate>.of(_monday))},
      );
      expect(_plan(index), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
    });

    test('a nudge rest ending today skips today; ending tomorrow skips both; ending yesterday skips none', () {
      expect(_plan(foodIndex, nudgeStates: <int, NudgeState>{1: _rest(1, _monday)}), <Nudge>[_nudge(tuesday, 1, 15, 30)]);
      expect(_plan(foodIndex, nudgeStates: <int, NudgeState>{1: _rest(1, tuesday)}), isEmpty);
      expect(_plan(foodIndex, nudgeStates: <int, NudgeState>{1: _rest(1, _monday.addDays(-1))}).length, 2);
    });

    test('the rest of another category does not hold this one back', () {
      expect(_plan(foodIndex, nudgeStates: <int, NudgeState>{2: _rest(2, tuesday)}).length, 2);
    });
  });

  group('NudgePlanner.plan: fallback (BR-22.2)', () {
    test('no habit and enough days: a general nudge at 20:00 today and tomorrow', () {
      final List<Nudge> plan = _plan(_index(const <UsualHabit>[]));
      expect(plan, <Nudge>[_nudge(_monday, null, 20, 0), _nudge(tuesday, null, 20, 0)]);
    });

    test('no habit and fewer than 10 days: none', () {
      expect(_plan(_index(const <UsualHabit>[]), hasEnoughDays: false), isEmpty);
    });

    test('an entry of any category today drops today only', () {
      final HabitIndex index = _index(const <UsualHabit>[], loggedToday: <int>{5});
      expect(_plan(index), <Nudge>[_nudge(tuesday, null, 20, 0)]);
    });

    test('a rested general nudge gives none for the days it rests', () {
      final HabitIndex index = _index(const <UsualHabit>[]);
      expect(_plan(index, nudgeStates: <int, NudgeState>{0: _rest(0, _monday)}), <Nudge>[_nudge(tuesday, null, 20, 0)]);
      expect(_plan(index, nudgeStates: <int, NudgeState>{0: _rest(0, tuesday)}), isEmpty);
    });

    test('the missed-log line asked today drops the general nudge for today', () {
      final HabitIndex index = _index(
        const <UsualHabit>[],
        states: <int, SuggestionState>{1: SuggestionState(categoryId: 1, askedOn: Option<CalendarDate>.of(_monday))},
      );
      expect(_plan(index), <Nudge>[_nudge(tuesday, null, 20, 0)]);
    });

    test('with a Regular habit that gives none today, the general nudge is not used', () {
      final HabitIndex index = _index(<UsualHabit>[_habit(food, dayType: DayType.weekend)]);
      expect(_plan(index), isEmpty);
    });

    test('now after 20:00: today is skipped', () {
      expect(_plan(_index(const <UsualHabit>[]), now: DateTime(2026, 10, 26, 20, 1)), <Nudge>[_nudge(tuesday, null, 20, 0)]);
    });
  });

  group('Nudge.id (BR-22.3)', () {
    test('is positive, fits 32 bits and differs by date and by category', () {
      final Set<int> ids = <int>{};
      for (int day = 0; day < 400; day++) {
        final CalendarDate date = _monday.addDays(day);
        for (final int? categoryId in <int?>[null, 1, 2, 13]) {
          final int id = _nudge(date, categoryId, 12, 0).id;
          expect(id, inInclusiveRange(1, 2147483647));
          expect(ids.add(id), isTrue, reason: '$date $categoryId');
        }
      }
    });

    test('the general nudge is category 0 of its date', () {
      expect(_nudge(_monday, null, 20, 0).id, NudgeRules.idOffset + 2490 * 1000);
    });

    // why: a bill reminder id is ruleId * 100000 + days since 2020 with days under 100000, so
    // with rule ids up to 19,999 the largest is below 2,000,000,000, where every nudge id starts.
    test('never equals a bill reminder id for rule ids up to 19,999', () {
      final int largestBill = BillReminder.idFor(19999, CalendarDate(2020, 1, 1).addDays(99999));
      final int smallestNudge = _nudge(const CalendarDate(2020, 1, 1), null, 20, 0).id;
      expect(largestBill, lessThan(smallestNudge));
      for (final int ruleId in <int>[1, 24, 2000, 19999]) {
        expect(BillReminder.idFor(ruleId, _monday), isNot(_nudge(_monday, null, 20, 0).id));
      }
    });
  });
}
