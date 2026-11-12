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
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';

import '../../helpers/fixtures/habits/chai_habit.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);

UsualHabit _habit({bool fading = false}) => UsualHabit(
      categoryId: 13,
      dayType: DayType.weekday,
      pooled: false,
      window: const TimeWindow(startMinute: 585, lengthMinutes: 60),
      amount: Money.fromMajor(20),
      hitDays: 18,
      activeDays: 20,
      lastHit: DateTime(2026, 10, 23, 10, 5),
      fading: fading,
    );

SuggestionState _state({Option<CalendarDate> quietOn = const Option<CalendarDate>.none()}) => SuggestionState(
      categoryId: 13,
      quietOn: quietOn,
      restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
      forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 9)),
    );

void main() {
  group('habits entities compare by their fields', () {
    test('SuggestionState', () {
      expect(_state(), _state());
      expect(_state(), isNot(_state(quietOn: const Option<CalendarDate>.of(_today))));
    });

    test('SuggestionState starts with nothing set', () {
      const SuggestionState state = SuggestionState(categoryId: 13);

      expect(state.quietOn, const Option<CalendarDate>.none());
      expect(state.restUntil, const Option<CalendarDate>.none());
      expect(state.forgottenAt, const Option<DateTime>.none());
    });

    test('UsualHabit', () {
      expect(_habit(), _habit());
      expect(_habit(), isNot(_habit(fading: true)));
    });

    test('HabitIndex', () {
      HabitIndex index(Set<int> loggedToday) => HabitIndex(
            builtOn: _today,
            habits: <UsualHabit>[_habit()],
            loggedToday: loggedToday,
            states: <int, SuggestionState>{13: _state()},
          );

      expect(index(<int>{13}), index(<int>{13}));
      expect(index(<int>{13}), isNot(index(<int>{1})));
    });

    test('HabitInputs', () {
      HabitInputs inputs(List<Category> categories) => HabitInputs(
            entries: <Entry>[entryAt(1, chai, 20, DateTime(2026, 10, 26, 10, 5))],
            categories: categories,
            states: <int, SuggestionState>{13: _state()},
          );

      expect(inputs(<Category>[chai]), inputs(<Category>[chai]));
      expect(inputs(<Category>[chai]), isNot(inputs(<Category>[food])));
    });
  });
}
