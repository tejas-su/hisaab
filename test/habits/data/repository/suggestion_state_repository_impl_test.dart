import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/data/datasource/suggestion_state_local_data_source.dart';
import 'package:hisaab/habits/data/repository/suggestion_state_repository_impl.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/suggestion_gate.dart';

import '../../../helpers/test_database.dart';

// why: the foreign key is on, so every state names a seeded category (ids 1–10).
final SuggestionState _food = SuggestionState(
  categoryId: 1,
  quietOn: const Option<CalendarDate>.of(CalendarDate(2026, 10, 26)),
  restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
  forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 10, 5)),
);
const SuggestionState _travel = SuggestionState(
  categoryId: 2,
  quietOn: Option<CalendarDate>.of(CalendarDate(2026, 10, 20)),
);

void main() {
  late AppDatabase database;
  late SuggestionStateRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = SuggestionStateRepositoryImpl(source: SqfliteSuggestionStateLocalDataSource(database));
  });

  Future<void> insertRaw(String column, String sqlValue) => database.db.rawInsert(
        'INSERT INTO ${Tables.suggestionState} (${SuggestionStateColumns.categoryId}, $column) VALUES (1, $sqlValue)',
      );

  group('SuggestionStateRepositoryImpl', () {
    test('put then of returns it', () async {
      expect(await repository.put(_food).run(), Either<Failure, Unit>.right(unit));

      expect(await repository.of(1).run(), Either<Failure, Option<SuggestionState>>.right(Option<SuggestionState>.of(_food)));
    });

    test('put replaces the state a category already has', () async {
      await repository.put(_food).run();

      await repository.put(const SuggestionState(categoryId: 1)).run();

      expect(
        await repository.of(1).run(),
        Either<Failure, Option<SuggestionState>>.right(const Option<SuggestionState>.of(SuggestionState(categoryId: 1))),
      );
    });

    test('of an unknown category is none', () async {
      await repository.put(_food).run();

      expect(await repository.of(2).run(), Either<Failure, Option<SuggestionState>>.right(const Option<SuggestionState>.none()));
    });

    test('all is keyed by category', () async {
      await repository.put(_food).run();
      await repository.put(_travel).run();

      expect(
        (await repository.all().run()).getOrElse((Failure f) => fail(f.message)),
        <int, SuggestionState>{1: _food, 2: _travel},
      );
    });

    test('all of an empty table is empty', () async {
      expect((await repository.all().run()).getOrElse((Failure f) => fail(f.message)), isEmpty);
    });

    test('remove deletes', () async {
      await repository.put(_food).run();
      await repository.put(_travel).run();

      expect(await repository.remove(1).run(), Either<Failure, Unit>.right(unit));

      expect((await repository.all().run()).getOrElse((Failure f) => fail(f.message)).keys, <int>[2]);
    });

    test('remove of a category with no state changes nothing', () async {
      await repository.put(_travel).run();

      expect(await repository.remove(1).run(), Either<Failure, Unit>.right(unit));

      expect((await repository.all().run()).getOrElse((Failure f) => fail(f.message)).keys, <int>[2]);
    });

    test('put for a category that does not exist is DatabaseFailure', () async {
      final Either<Failure, Unit> result = await repository.put(const SuggestionState(categoryId: 999)).run();

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('a thrown read is DatabaseFailure', () async {
      await database.close();

      expect((await repository.all().run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect((await repository.of(1).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('a thrown write is DatabaseFailure', () async {
      await database.close();

      expect((await repository.put(_food).run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect((await repository.remove(1).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('an unreadable row is InvalidDataFailure', () async {
      await insertRaw(SuggestionStateColumns.quietOn, "X'00'");

      expect((await repository.all().run()).getLeft().toNullable(), isA<InvalidDataFailure>());
      expect((await repository.of(1).run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('a row with a date that does not exist is InvalidDataFailure', () async {
      await insertRaw(SuggestionStateColumns.restUntil, "'2026-02-30'");

      expect((await repository.all().run()).getLeft().toNullable(), isA<InvalidDataFailure>());
      expect((await repository.of(1).run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('markAsked on a category with no state stores a state with only asked_on', () async {
      expect(await repository.markAsked(1, const CalendarDate(2026, 10, 27)).run(), Either<Failure, Unit>.right(unit));

      expect(
        await repository.of(1).run(),
        Either<Failure, Option<SuggestionState>>.right(
          const Option<SuggestionState>.of(
            SuggestionState(categoryId: 1, askedOn: Option<CalendarDate>.of(CalendarDate(2026, 10, 27))),
          ),
        ),
      );
    });

    test('a state with only asked_on is gate-open: no quiet, no rest (BR-17)', () async {
      await repository.markAsked(1, const CalendarDate(2026, 10, 27)).run();
      final SuggestionState state = (await repository.of(1).run()).getOrElse((Failure f) => fail(f.message)).toNullable()!;

      expect(
        SuggestionGate.statusOf(Option<SuggestionState>.of(state), today: const CalendarDate(2026, 10, 27)),
        GateStatus.open,
      );
    });

    test('markAsked keeps the other columns of a state', () async {
      await repository.put(_food).run();

      await repository.markAsked(1, const CalendarDate(2026, 10, 27)).run();

      final SuggestionState state = (await repository.of(1).run()).getOrElse((Failure f) => fail(f.message)).toNullable()!;
      expect(state.quietOn, _food.quietOn);
      expect(state.restUntil, _food.restUntil);
      expect(state.forgottenAt, _food.forgottenAt);
      expect(state.askedOn, const Option<CalendarDate>.of(CalendarDate(2026, 10, 27)));
    });

    test('markAsked for a category that does not exist is DatabaseFailure', () async {
      final Either<Failure, Unit> result = await repository.markAsked(999, const CalendarDate(2026, 10, 27)).run();

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('a row with a bad asked_on is InvalidDataFailure', () async {
      await insertRaw(SuggestionStateColumns.askedOn, "'2026-02-30'");

      expect((await repository.of(1).run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });
}
