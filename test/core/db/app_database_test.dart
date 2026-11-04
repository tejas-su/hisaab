import 'dart:io';

import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/db/migrations/migration_001_initial.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AppDatabase> _openOrFail(String path) async {
  final Either<Failure, AppDatabase> opened =
      await AppDatabase.open(factory: databaseFactoryFfi, path: path, singleInstance: false).run();
  return opened.getOrElse((Failure failure) => fail(failure.message));
}

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  Database db() => database.db;

  setUp(() async {
    database = await _openOrFail(inMemoryDatabasePath);
  });

  tearDown(() => database.close());

  Future<int> insertEntry({
    int amountMinor = 42000,
    int categoryId = 1,
    String date = '2026-10-26',
    int? recurringId,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      db().insert(Tables.transactions, <String, Object?>{
        TransactionColumns.amountMinor: amountMinor,
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: categoryId,
        TransactionColumns.date: date,
        TransactionColumns.recurringId: recurringId,
        TransactionColumns.createdAt: '2026-10-26T10:00:00',
      }, conflictAlgorithm: conflictAlgorithm);

  Future<int> insertRule({bool incomeSource = false, String label = 'Salary'}) =>
      db().insert(Tables.recurring, <String, Object?>{
        RecurringColumns.label: label,
        RecurringColumns.amountMinor: 4500000,
        RecurringColumns.kind: EntryKindValues.got,
        RecurringColumns.categoryId: 9,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-04',
        RecurringColumns.nextDue: '2026-11-04',
        RecurringColumns.isIncomeSource: incomeSource ? 1 : 0,
      });

  group('AppDatabase v1 schema', () {
    test('is at the latest schema version', () async {
      final List<Map<String, Object?>> rows = await db().rawQuery('PRAGMA user_version');
      expect(rows.single.values.single, AppDatabase.schemaVersion);
      expect(AppDatabase.schemaVersion, 2);
    });

    test('seeds the fixed category list in order (SPEC BR-11)', () async {
      final List<Map<String, Object?>> rows = await db().query(
        Tables.categories,
        columns: <String>[CategoryColumns.key, CategoryColumns.kind],
        orderBy: '${CategoryColumns.kind} DESC, ${CategoryColumns.sort}',
      );
      expect(rows.map((Map<String, Object?> row) => row[CategoryColumns.key]).toList(), <String>[
        'food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other', 'salary', 'other_income',
      ]);
    });

    test('seeds the default money settings', () async {
      final List<Map<String, Object?>> rows = await db().query(Tables.settings);
      final Map<Object?, Object?> settings = <Object?, Object?>{
        for (final Map<String, Object?> row in rows) row[SettingsColumns.key]: row[SettingsColumns.value],
      };
      expect(settings[SettingKeys.currency], 'INR');
      expect(settings[SettingKeys.monthStart], 'payday');
    });

    test('enforces foreign keys', () async {
      expect(() => insertEntry(categoryId: 999), throwsA(isA<DatabaseException>()));
    });

    test('rejects zero and negative amounts', () async {
      expect(() => insertEntry(amountMinor: 0), throwsA(isA<DatabaseException>()));
      expect(() => insertEntry(amountMinor: -100), throwsA(isA<DatabaseException>()));
    });

    test('rejects notes longer than 80 characters (SPEC BR-10)', () async {
      Future<int> insertWithNote(String note) => db().insert(Tables.transactions, <String, Object?>{
            TransactionColumns.amountMinor: 100,
            TransactionColumns.kind: EntryKindValues.spent,
            TransactionColumns.categoryId: 1,
            TransactionColumns.date: '2026-10-26',
            TransactionColumns.note: note,
            TransactionColumns.createdAt: '2026-10-26T10:00:00',
          });
      expect(await insertWithNote('a' * 80), greaterThan(0));
      expect(() => insertWithNote('a' * 81), throwsA(isA<DatabaseException>()));
    });

    test('a recurring occurrence is stored once per date even when posted twice (SPEC BR-9, E8)', () async {
      final int ruleId = await insertRule();
      const ConflictAlgorithm ignore = ConflictAlgorithm.ignore;
      await insertEntry(recurringId: ruleId, date: '2026-11-04', conflictAlgorithm: ignore);
      await insertEntry(recurringId: ruleId, date: '2026-11-04', conflictAlgorithm: ignore);
      await insertEntry(recurringId: ruleId, date: '2026-12-04', conflictAlgorithm: ignore);
      final List<Map<String, Object?>> rows =
          await db().query(Tables.transactions, where: '${TransactionColumns.recurringId} = ?', whereArgs: <Object?>[ruleId]);
      expect(rows, hasLength(2));
    });

    test('OR IGNORE also swallows CHECK violations, so posts must be validated first', () async {
      expect(await insertEntry(amountMinor: 0, conflictAlgorithm: ConflictAlgorithm.ignore), 0);
      expect(await db().query(Tables.transactions), isEmpty);
    });

    test('manual entries on the same day are all kept', () async {
      await insertEntry();
      await insertEntry();
      expect(await db().query(Tables.transactions), hasLength(2));
    });

    test('allows only one active income-source rule', () async {
      await insertRule(incomeSource: true);
      expect(() => insertRule(incomeSource: true, label: 'Second salary'), throwsA(isA<DatabaseException>()));
      expect(await insertRule(label: 'Rent'), greaterThan(0));
    });
  });

  group('AppDatabase v2 schema', () {
    test('a new database stores a bill icon per rule (D118)', () async {
      final int id = await insertRule(label: 'Gas');
      await db().update(Tables.recurring, <String, Object?>{RecurringColumns.icon: 'gas'}, where: '${RecurringColumns.id} = ?', whereArgs: <Object?>[id]);
      final List<Map<String, Object?>> rows = await db().query(Tables.recurring);
      expect(rows.single[RecurringColumns.icon], 'gas');
    });
  });

  group('AppDatabase on disk', () {
    test('reopening keeps data and does not re-run migrations', () async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_test');
      addTearDown(() => dir.delete(recursive: true));
      final String path = p.join(dir.path, AppDatabase.fileName);

      final AppDatabase first = await _openOrFail(path);
      await first.db.insert(Tables.settings, <String, Object?>{SettingsColumns.key: 'probe', SettingsColumns.value: '1'});
      await first.close();

      final AppDatabase second = await _openOrFail(path);
      addTearDown(second.close);
      expect(await second.db.query(Tables.settings, where: "${SettingsColumns.key} = 'probe'"), hasLength(1));
      expect(await second.db.query(Tables.categories), hasLength(10));
    });

    test('upgrading a v1 database adds an empty bill icon to each rule (D118)', () async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_v1');
      addTearDown(() => dir.delete(recursive: true));
      final String path = p.join(dir.path, AppDatabase.fileName);
      final Database v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 1, onCreate: (Database db, int _) => migration001Initial(db)),
      );
      await v1.insert(Tables.recurring, <String, Object?>{
        RecurringColumns.label: 'Rent',
        RecurringColumns.amountMinor: 1800000,
        RecurringColumns.kind: EntryKindValues.spent,
        RecurringColumns.categoryId: 7,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
      });
      await v1.close();

      final AppDatabase upgraded = await _openOrFail(path);
      addTearDown(upgraded.close);
      final List<Map<String, Object?>> rows = await upgraded.db.query(Tables.recurring);
      expect(rows.single[RecurringColumns.label], 'Rent');
      expect(rows.single.containsKey(RecurringColumns.icon), isTrue);
      expect(rows.single[RecurringColumns.icon], isNull);
    });

    test('returns DatabaseFailure instead of throwing when the file cannot be opened', () async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_bad');
      addTearDown(() => dir.delete(recursive: true));
      final Either<Failure, AppDatabase> opened =
          await AppDatabase.open(factory: databaseFactoryFfi, path: dir.path, singleInstance: false).run();
      expect(opened.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
