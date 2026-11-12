import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/time_window.dart';
import 'package:hisaab/habits/domain/entities/usual_habit.dart';
import 'package:hisaab/habits/domain/usecase/get_habit_index.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const CalendarDate _today = WorkedExample.today;

void main() {
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeSuggestionStateRepository states;
  late FakeClock clock;
  late GetHabitIndex getIndex;

  void build(List<Entry> entries) {
    ledger = FakeLedgerRepository(entries);
    categories = FakeCategoryRepository(<Category>[...seedCategories, chai]);
    states = FakeSuggestionStateRepository();
    clock = FakeClock(DateTime(2026, 10, 26, 10, 5));
    getIndex = GetHabitIndex(ledger: ledger, categories: categories, states: states, clock: clock);
  }

  tearDown(() => ledger.dispose());

  Future<HabitIndex> index() async =>
      (await getIndex(const NoParams()).run()).getOrElse((Failure failure) => fail(failure.message));

  group('GetHabitIndex', () {
    test('builds the worked example\'s index for today', () async {
      build(chaiWeekdays(today: _today));

      final HabitIndex built = await index();

      expect(built.builtOn, _today);
      final UsualHabit habit = built.habits.single;
      expect(habit.categoryId, chai.id);
      expect(habit.dayType, DayType.weekday);
      expect(habit.amount, Money.fromMajor(20));
      expect(habit.window, const TimeWindow(startMinute: 585, lengthMinutes: 60));
      expect(<int>[habit.hitDays, habit.activeDays], <int>[18, 20]);
      expect(built.loggedToday, isEmpty);
      expect(built.states, isEmpty);
    });

    test('asks the ledger for exactly today − 55 … today', () async {
      build(const <Entry>[]);

      await index();

      expect(ledger.reads, <(CalendarDate, CalendarDate)>[(const CalendarDate(2026, 9, 1), _today)]);
    });

    test('the 56 days cross New Year and 29 February', () async {
      build(const <Entry>[]);
      clock.current = DateTime(2028, 3, 10, 9);

      final HabitIndex built = await index();

      expect(ledger.reads.single, (const CalendarDate(2028, 1, 15), const CalendarDate(2028, 3, 10)));
      expect(built.builtOn, const CalendarDate(2028, 3, 10));
    });

    test('an entry dated today marks its category as logged today', () async {
      build(<Entry>[...chaiWeekdays(today: _today), entryAt(900, chai, 20, DateTime(2026, 10, 26, 9, 50))]);

      expect((await index()).loggedToday, <int>{chai.id});
    });

    test('carries the stored states and leaves out what was logged before Forget', () async {
      build(chaiWeekdays(today: _today));
      final SuggestionState forgotten = SuggestionState(
        categoryId: chai.id,
        forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 8)),
      );
      states.states[chai.id] = forgotten;

      final HabitIndex built = await index();

      expect(built.states, <int, SuggestionState>{chai.id: forgotten});
      expect(built.habits, isEmpty);
    });

    test('a hidden category has no habit', () async {
      build(chaiWeekdays(today: _today));
      await categories.setHidden(chai.id, hidden: true).run();

      expect((await index()).habits, isEmpty);
    });

    test('an empty ledger gives an empty index', () async {
      build(const <Entry>[]);

      expect(await index(), HabitIndex.empty(_today));
    });

    test('a ledger failure is returned', () async {
      build(chaiWeekdays(today: _today));
      ledger.failure = DatabaseFailure('ledger');

      expect((await getIndex(const NoParams()).run()).getLeft().toNullable(), ledger.failure);
    });

    test('a category failure is returned', () async {
      build(chaiWeekdays(today: _today));
      categories.failure = DatabaseFailure('categories');

      expect((await getIndex(const NoParams()).run()).getLeft().toNullable(), categories.failure);
    });

    test('a state failure is returned', () async {
      build(chaiWeekdays(today: _today));
      states.failure = const InvalidDataFailure('states');

      expect((await getIndex(const NoParams()).run()).getLeft().toNullable(), states.failure);
    });
  });
}
