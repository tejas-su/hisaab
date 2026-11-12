import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/entities/usual_habit.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);

UsualHabit _habit(int categoryId, DayType dayType) => UsualHabit(
      categoryId: categoryId,
      dayType: dayType,
      pooled: false,
      window: const TimeWindow(startMinute: 585, lengthMinutes: 60),
      amount: Money.fromMajor(20),
      hitDays: 18,
      activeDays: 20,
      lastHit: DateTime(2026, 10, 23, 10, 5),
      fading: false,
    );

HabitIndex _index(List<UsualHabit> habits) => HabitIndex(
      builtOn: _today,
      habits: habits,
      loggedToday: const <int>{},
      states: const <int, SuggestionState>{},
    );

void main() {
  group('HabitIndex', () {
    test('empty has no habits, nothing logged and no states', () {
      expect(HabitIndex.empty(_today), _index(const <UsualHabit>[]));
    });

    group('habitFor (FR-SE-2 AC-6)', () {
      test("prefers today's day type", () {
        final HabitIndex index = _index(<UsualHabit>[_habit(13, DayType.weekday), _habit(13, DayType.weekend)]);

        expect(
          index.habitFor(13, preferring: DayType.weekend),
          Option<UsualHabit>.of(_habit(13, DayType.weekend)),
        );
        expect(
          index.habitFor(13, preferring: DayType.weekday),
          Option<UsualHabit>.of(_habit(13, DayType.weekday)),
        );
      });

      test('then the other day type', () {
        final HabitIndex index = _index(<UsualHabit>[_habit(13, DayType.weekday)]);

        expect(
          index.habitFor(13, preferring: DayType.weekend),
          Option<UsualHabit>.of(_habit(13, DayType.weekday)),
        );
      });

      test('then none', () {
        final HabitIndex index = _index(<UsualHabit>[_habit(1, DayType.weekday)]);

        expect(index.habitFor(13, preferring: DayType.weekday), const Option<UsualHabit>.none());
        expect(HabitIndex.empty(_today).habitFor(13, preferring: DayType.weekday), const Option<UsualHabit>.none());
      });
    });
  });
}
