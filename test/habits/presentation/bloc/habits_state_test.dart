import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';

void main() {
  final Entry tapped = entryAt(900, chai, 20, DateTime(2026, 10, 26, 10, 5));
  final UsualAdd added = UsualAdd(entry: tapped, category: chai);
  final UsualAdd other = UsualAdd(entry: tapped, category: food);
  final HabitIndex monday = HabitIndex.empty(const CalendarDate(2026, 10, 26));
  final HabitIndex tuesday = HabitIndex.empty(const CalendarDate(2026, 10, 27));

  group('HabitsState', () {
    test('states compare by their fields', () {
      expect(const HabitsLoading(), const HabitsLoading());
      expect(HabitsReady(monday), HabitsReady(monday));
      expect(HabitsReady(monday), isNot(HabitsReady(tuesday)));
      expect(HabitsReady(monday), isNot(HabitsReady(monday, added: Option<UsualAdd>.of(added))));
      expect(
        HabitsReady(monday, added: Option<UsualAdd>.of(added)),
        isNot(HabitsReady(monday, added: Option<UsualAdd>.of(other))),
      );
      expect(HabitsReady(monday), isNot(const HabitsLoading()));
    });

    test('the states and events without fields compare by type alone', () {
      expect(const HabitsLoading().props, isEmpty);
      expect(const HabitsLoadRequested().props, isEmpty);
    });

    test('a ready state offers no Undo unless it is given one', () {
      expect(HabitsReady(monday).added, const Option<UsualAdd>.none());
    });
  });

  group('HabitsEvent', () {
    test('events compare by their fields', () {
      expect(const HabitsLoadRequested(), const HabitsLoadRequested());
      expect(HabitsUsualAdded(added), HabitsUsualAdded(added));
      expect(HabitsUsualAdded(added), isNot(HabitsUsualAdded(other)));
      expect(HabitsUsualUndoRequested(added), HabitsUsualUndoRequested(added));
      expect(HabitsUsualUndoRequested(added), isNot(HabitsUsualUndoRequested(other)));
      expect(HabitsUsualAdded(added), isNot(HabitsUsualUndoRequested(added)));
    });
  });
}
