import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/notifications/nudge_notice.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/domain/entities/nudge_state.dart';
import 'package:hisaab/habits/domain/usecase/arm_nudges.dart';
import 'package:hisaab/habits/domain/usecase/get_habit_index.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_nudge_state_repository.dart';
import '../../../helpers/fakes/fake_nudges.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';

/// Mon 26 Oct 2026, 10:05; Chai's window ends 10:45, so its nudge is armed for 12:15.
final DateTime _monday = DateTime(2026, 10, 26, 10, 5);
const CalendarDate _mondayDate = CalendarDate(2026, 10, 26);
final DateTime _mondayNudge = DateTime(2026, 10, 26, 12, 15);

/// Sat 24 Oct: no Chai habit day, so a state armed for it is settled by what was logged then.
final DateTime _saturdayNudge = DateTime(2026, 10, 24, 12, 15);

void main() {
  late FakeLedgerRepository ledger;
  late FakeNudgeStateRepository states;
  late FakeNudges nudges;
  late ArmNudges armNudges;

  void build(List<Entry> entries, {DateTime? now, Iterable<NudgeState> stored = const <NudgeState>[], List<Category>? categories}) {
    final FakeClock clock = FakeClock(now ?? _monday);
    final FakeCategoryRepository categoryRepository = FakeCategoryRepository(categories ?? <Category>[...seedCategories, chai]);
    ledger = FakeLedgerRepository(entries);
    states = FakeNudgeStateRepository(stored);
    nudges = FakeNudges();
    armNudges = ArmNudges(
      getHabitIndex: GetHabitIndex(
        ledger: ledger,
        categories: categoryRepository,
        states: FakeSuggestionStateRepository(),
        clock: clock,
      ),
      nudgeStates: states,
      ledger: ledger,
      categories: categoryRepository,
      nudges: nudges,
      clock: clock,
      categoryLabel: (Category category) => category.customName ?? category.key,
    );
  }

  tearDown(() async {
    await ledger.dispose();
    await nudges.dispose();
  });

  List<Entry> chaiHabit() => chaiWeekdays(today: _mondayDate);

  Entry chaiAt(DateTime at, {int id = 900}) => entryAt(id, chai, 20, at);

  NudgeState chaiState({Option<DateTime>? armedFor, int streak = 0}) => NudgeState(
        categoryId: chai.id,
        armedFor: armedFor ?? Option<DateTime>.of(_saturdayNudge),
        ignoredStreak: streak,
      );

  group('ArmNudges (BR-22)', () {
    test('switched off: removes every nudge and clears armedFor, keeping streak and rest (BR-22.4)', () async {
      build(chaiHabit(), stored: <NudgeState>[chaiState(streak: 2)]);

      final Either<Failure, Unit> result = await armNudges(false).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(nudges.arms, 1);
      expect(nudges.scheduled, isEmpty);
      expect(states.states[chai.id], const NudgeState(categoryId: 13, ignoredStreak: 2));
    });

    test('switched off writes nothing when no state is armed', () async {
      build(chaiHabit(), stored: const <NudgeState>[NudgeState(categoryId: 13, ignoredStreak: 1)]);

      await armNudges(false).run();

      expect(states.states[chai.id], const NudgeState(categoryId: 13, ignoredStreak: 1));
    });

    test('off, then on later: the cancelled nudge is not settled as ignored', () async {
      build(chaiHabit(), stored: <NudgeState>[chaiState(streak: 2)]);

      await armNudges(false).run();
      await armNudges(true).run();

      expect(states.states[chai.id]?.ignoredStreak, 2);
      expect(states.states[chai.id]?.restUntil, const Option<CalendarDate>.none());
    });

    test('switched off with an unreadable state: Left, after the nudges were removed', () async {
      build(chaiHabit());
      states.failure = DatabaseFailure('locked');

      expect((await armNudges(false).run()).isLeft(), isTrue);
      expect(nudges.arms, 1);
    });

    test('a Regular habit: arms the category by name at the window end + 90 min and stores armedFor', () async {
      build(chaiHabit());

      await armNudges(true).run();

      expect(nudges.scheduled.first.categoryName, Option<String>.of('Chai'));
      expect(nudges.scheduled.first.at, _mondayNudge);
      expect(states.states[chai.id]?.armedFor, Option<DateTime>.of(_mondayNudge));
    });

    test('records only the earliest nudge of a category; a later run records the next', () async {
      build(chaiHabit());

      await armNudges(true).run();

      expect(nudges.scheduled, hasLength(2));
      expect(states.states[chai.id]?.armedFor, Option<DateTime>.of(_mondayNudge));
    });

    test('E124: a past armedFor restored from a backup is settled once, with a worked entry resetting the streak', () async {
      build(<Entry>[...chaiHabit(), chaiAt(DateTime(2026, 10, 24, 12, 30))], stored: <NudgeState>[chaiState(streak: 2)]);

      await armNudges(true).run();

      expect(states.states[chai.id]?.ignoredStreak, 0);
    });

    test('ignored a third time in a row: the rest is stored', () async {
      build(chaiHabit(), stored: <NudgeState>[chaiState(streak: 2)]);

      final Either<Failure, Unit> result = await armNudges(true).run();

      expect(result.isRight(), isTrue);
      expect(states.states[chai.id]?.restUntil, Option<CalendarDate>.of(const CalendarDate(2026, 11, 23)));
      expect(states.states[chai.id]?.armedFor, const Option<DateTime>.none());
      expect(nudges.scheduled, isEmpty);
    });

    test('an entry logged before the nudge time cancels it: the streak is unchanged', () async {
      build(<Entry>[...chaiHabit(), chaiAt(DateTime(2026, 10, 24, 11))], stored: <NudgeState>[chaiState(streak: 2)]);

      await armNudges(true).run();

      expect(states.states[chai.id]?.ignoredStreak, 2);
      expect(states.states[chai.id]?.restUntil, const Option<CalendarDate>.none());
    });

    test('a Not logged fix and a hidden category do not count as logging', () async {
      final List<Category> categories = <Category>[
        ...seedCategories.map((Category c) => c.key == 'fun' ? c.copyWith(hidden: true) : c),
        chai,
      ];
      build(
        <Entry>[
          ...chaiHabit(),
          notLogged(10, const CalendarDate(2026, 10, 24)),
          entryAt(901, categories.firstWhere((Category c) => c.key == 'fun'), 20, DateTime(2026, 10, 24, 12, 30)),
        ],
        stored: <NudgeState>[chaiState(streak: 2)],
        categories: categories,
      );

      await armNudges(true).run();

      expect(states.states[chai.id]?.restUntil, isA<Some<CalendarDate>>());
    });

    test('E124: a future armedFor is re-derived, and a past one inside its hour waits to be settled', () async {
      build(chaiHabit(), now: DateTime(2026, 10, 24, 12, 30), stored: <NudgeState>[chaiState(streak: 1)]);

      await armNudges(true).run();

      expect(states.states[chai.id]?.armedFor, Option<DateTime>.of(_saturdayNudge));
      expect(states.states[chai.id]?.ignoredStreak, 1);
    });

    test('a write that makes the condition false: the notice is gone and armedFor is cleared', () async {
      // Fri 23 Oct: tomorrow is a weekend, which has no Chai habit.
      final DateTime friday = DateTime(2026, 10, 23, 10, 5);
      build(
        <Entry>[...chaiWeekdays(today: const CalendarDate(2026, 10, 23)), chaiAt(DateTime(2026, 10, 23, 9, 50))],
        now: friday,
        stored: <NudgeState>[chaiState(armedFor: Option<DateTime>.of(DateTime(2026, 10, 23, 12, 15)), streak: 1)],
      );

      await armNudges(true).run();

      expect(nudges.scheduled, isEmpty);
      expect(states.states[chai.id]?.armedFor, const Option<DateTime>.none());
      expect(states.states[chai.id]?.ignoredStreak, 1);
    });

    test('the general nudge has no category name and is stored under 0', () async {
      build(warmUpFood(_mondayDate));

      await armNudges(true).run();

      expect(nudges.scheduled.first, NudgeNotice(id: nudges.scheduled.first.id, at: DateTime(2026, 10, 26, 20), categoryName: const Option<String>.none()));
      expect(states.states[0]?.armedFor, Option<DateTime>.of(DateTime(2026, 10, 26, 20)));
    });

    test('10 active days but under 14 since the first: no general nudge (BR-17 rule 1)', () async {
      build(foodOn(List<CalendarDate>.generate(10, (int day) => _mondayDate.addDays(day - 10))));

      await armNudges(true).run();

      expect(nudges.scheduled, isEmpty);
    });

    test('fewer than 10 days with a learned entry: no general nudge', () async {
      build(warmUpFood(_mondayDate).take(9).toList());

      await armNudges(true).run();

      expect(nudges.scheduled, isEmpty);
    });

    test('the general nudge is settled by any shown category logged in its hour', () async {
      build(
        <Entry>[...warmUpFood(_mondayDate), entryAt(902, food, 20, DateTime(2026, 10, 24, 20, 20))],
        stored: const <NudgeState>[NudgeState(categoryId: 0, ignoredStreak: 2)]
            .map((NudgeState s) => NudgeState(categoryId: 0, armedFor: Option<DateTime>.of(DateTime(2026, 10, 24, 20)), ignoredStreak: s.ignoredStreak))
            .toList(),
      );

      await armNudges(true).run();

      expect(states.states[0]?.ignoredStreak, 0);
    });

    test('E122: nothing is armed and nothing throws when the system refuses (arm swallows), and a failed read returns Left', () async {
      build(chaiHabit());
      states.failure = DatabaseFailure('locked');

      final Either<Failure, Unit> result = await armNudges(true).run();

      expect(result, Either<Failure, Unit>.left(DatabaseFailure('locked')));
      expect(nudges.arms, 0);
    });

    test('a failed ledger read arms nothing and returns Left', () async {
      build(chaiHabit());
      ledger.failure = DatabaseFailure('locked');

      expect((await armNudges(true).run()).isLeft(), isTrue);
      expect(nudges.arms, 0);
    });
  });
}
