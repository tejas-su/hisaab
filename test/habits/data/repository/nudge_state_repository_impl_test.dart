import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/data/datasource/nudge_state_local_data_source.dart';
import 'package:hisaab/habits/data/repository/nudge_state_repository_impl.dart';
import 'package:hisaab/habits/domain/entities/nudge_state.dart';

import '../../../helpers/test_database.dart';

final NudgeState _food = NudgeState(
  categoryId: 1,
  armedFor: Option<DateTime>.of(DateTime(2026, 11, 18, 20, 30)),
  ignoredStreak: 2,
  restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
);
const NudgeState _general = NudgeState(categoryId: 0);

void main() {
  late AppDatabase database;
  late NudgeStateRepositoryImpl repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = NudgeStateRepositoryImpl(source: SqfliteNudgeStateLocalDataSource(database));
  });

  Future<Map<int, NudgeState>> all() async => (await repository.all().run()).getOrElse((Failure f) => fail(f.message));

  Future<Either<Failure, Map<int, NudgeState>>> allAfterRaw(String column, String sqlValue) async {
    await database.db.rawInsert('INSERT INTO ${Tables.nudgeState} (${NudgeStateColumns.categoryId}, $column) VALUES (1, $sqlValue)');
    return repository.all().run();
  }

  group('NudgeStateRepositoryImpl', () {
    test('all of an empty table is empty', () async {
      expect(await all(), isEmpty);
    });

    test('put then all round trips a full row and the general (0) row with every Option none', () async {
      await repository.put(_food).run();
      await repository.put(_general).run();

      expect(await all(), <int, NudgeState>{0: _general, 1: _food});
    });

    test('armed_for is a local ISO instant and rest_until a day', () async {
      await repository.put(_food).run();

      final List<Map<String, Object?>> rows = await database.db.query(Tables.nudgeState);

      expect(rows.single[NudgeStateColumns.armedFor], '2026-11-18T20:30:00.000');
      expect(rows.single[NudgeStateColumns.restUntil], '2026-11-25');
    });

    test('put twice replaces', () async {
      await repository.put(_food).run();
      await repository.put(const NudgeState(categoryId: 1, ignoredStreak: 1)).run();

      expect(await all(), <int, NudgeState>{1: const NudgeState(categoryId: 1, ignoredStreak: 1)});
    });

    test('clear empties the table', () async {
      await repository.put(_food).run();
      await repository.put(_general).run();

      expect((await repository.clear().run()).isRight(), isTrue);

      expect(await all(), isEmpty);
    });

    test('an unreadable armed_for is InvalidDataFailure', () async {
      expect((await allAfterRaw(NudgeStateColumns.armedFor, "'nope'")).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('an unreadable rest_until is InvalidDataFailure', () async {
      expect((await allAfterRaw(NudgeStateColumns.restUntil, "'nope'")).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('a bad column type is a failure, not a crash', () async {
      expect((await allAfterRaw(NudgeStateColumns.ignoredStreak, "'x'")).isLeft(), isTrue);
    });
  });
}
