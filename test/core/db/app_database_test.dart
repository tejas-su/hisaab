import 'dart:io';

import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/db/migrations/migration_001_initial.dart';
import 'package:hisaab/core/db/migrations/migration_002_bill_icon.dart';
import 'package:hisaab/core/db/migrations/migrations.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/core/errors/failure.dart';
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
      expect(AppDatabase.schemaVersion, 5);
    });

    test('seeds the fixed category list in order (SPEC BR-11)', () async {
      final List<Map<String, Object?>> rows = await db().query(
        Tables.categories,
        columns: <String>[CategoryColumns.key, CategoryColumns.kind],
        where: '${CategoryColumns.archived} = 0',
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

  group('Schema v3 (D120)', () {
    Future<String> oldFile(int version, Future<void> Function(Database db) fill) async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_v$version');
      addTearDown(() => dir.delete(recursive: true));
      final String path = p.join(dir.path, AppDatabase.fileName);
      final Database old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (Database db, int _) async {
            await migration001Initial(db);
            if (version >= 2) {
              await migration002BillIcon(db);
            }
          },
        ),
      );
      await fill(old);
      await old.close();
      return path;
    }

    Map<String, Object?> rule({required int id, required String kind, required int categoryId, String label = 'Rent', bool income = false}) =>
        <String, Object?>{
          RecurringColumns.id: id,
          RecurringColumns.label: label,
          RecurringColumns.amountMinor: income ? 4500000 : 820000,
          RecurringColumns.kind: kind,
          RecurringColumns.categoryId: categoryId,
          RecurringColumns.frequency: FrequencyValues.monthly,
          RecurringColumns.anchorDate: income ? '2026-10-04' : '2026-10-05',
          RecurringColumns.nextDue: income ? '2026-11-04' : '2026-11-05',
          RecurringColumns.isIncomeSource: income ? 1 : 0,
        };

    Map<String, Object?> entry({required int id, required String kind, required int categoryId, required String date, int? recurringId, String? note}) =>
        <String, Object?>{
          TransactionColumns.id: id,
          TransactionColumns.amountMinor: 42000,
          TransactionColumns.kind: kind,
          TransactionColumns.categoryId: categoryId,
          TransactionColumns.date: date,
          TransactionColumns.note: note,
          TransactionColumns.recurringId: recurringId,
          TransactionColumns.createdAt: '2026-10-26T10:00:00',
        };

    Future<void> salaryRentAndEntries(Database db) async {
      await db.insert(Tables.recurring, rule(id: 1, kind: EntryKindValues.got, categoryId: 9, label: 'Salary', income: true));
      await db.insert(Tables.recurring, rule(id: 2, kind: EntryKindValues.spent, categoryId: 7));
      await db.insert(Tables.transactions, entry(id: 1, kind: EntryKindValues.got, categoryId: 9, date: '2026-10-04', recurringId: 1));
      await db.insert(Tables.transactions, entry(id: 2, kind: EntryKindValues.spent, categoryId: 7, date: '2026-10-05', recurringId: 2));
      await db.insert(Tables.transactions, entry(id: 3, kind: EntryKindValues.spent, categoryId: 1, date: '2026-10-26', note: 'Chai'));
    }

    Future<void> keepAside(Database db, String value) =>
        db.insert(Tables.settings, <String, Object?>{SettingsColumns.key: SettingKeys.keepAsideMinor, SettingsColumns.value: value});

    Future<List<String>> indexNames(Database db, String table) async =>
        (await db.rawQuery('PRAGMA index_list($table)')).map((Map<String, Object?> row) => row['name']! as String).toList();

    test('upgrading a v1 database keeps ids, links and indexes', () async {
      final String path = await oldFile(1, salaryRentAndEntries);
      final AppDatabase upgraded = await _openOrFail(path);
      addTearDown(upgraded.close);
      final Database db = upgraded.db;
      expect((await db.rawQuery('PRAGMA user_version')).single.values.single, 5);
      final List<Map<String, Object?>> entries = await db.query(Tables.transactions, orderBy: TransactionColumns.id);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.id]), <int>[1, 2, 3]);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.recurringId]), <int?>[1, 2, null]);
      expect(entries[2][TransactionColumns.note], 'Chai');
      final List<Map<String, Object?>> rules = await db.query(Tables.recurring, orderBy: RecurringColumns.id);
      expect(rules.map((Map<String, Object?> r) => r[RecurringColumns.id]), <int>[1, 2]);
      expect(rules.map((Map<String, Object?> r) => r[RecurringColumns.icon]), <Object?>[null, null]);
      expect(rules.map((Map<String, Object?> r) => r[RecurringColumns.amountMode]), <String>['fixed', 'fixed']);
      expect((await db.rawQuery('PRAGMA foreign_key_list(${Tables.transactions})')).map((Map<String, Object?> r) => r['table']),
          contains(Tables.recurring));
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(await indexNames(db, Tables.transactions),
          containsAll(<String>['ux_transactions_recurring_date', 'ix_transactions_date', 'ix_transactions_category_date']));
      expect(await indexNames(db, Tables.recurring), contains('ux_recurring_one_income_source'));
      final int again = await db.insert(
        Tables.transactions,
        <String, Object?>{...entry(id: 9, kind: EntryKindValues.spent, categoryId: 7, date: '2026-10-05', recurringId: 2)}..remove(TransactionColumns.id),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      expect(await db.query(Tables.transactions, where: '${TransactionColumns.recurringId} = 2'), hasLength(1));
      expect(again, isNot(9));
    });

    test('v3 accepts saved and card entries and save rules', () async {
      Future<int> addEntry(String kind) => db().insert(Tables.transactions,
          <String, Object?>{...entry(id: 0, kind: kind, categoryId: 1, date: '2026-10-26')}..remove(TransactionColumns.id));
      Future<int> addRule(String kind, {String? mode}) => db().insert(Tables.recurring, <String, Object?>{
            ...rule(id: 0, kind: kind, categoryId: 4)..remove(RecurringColumns.id),
            RecurringColumns.amountMode: ?mode,
          });
      expect(await addEntry(EntryKindValues.saved), greaterThan(0));
      expect(await addEntry(EntryKindValues.cardPaid), greaterThan(0));
      await expectLater(addEntry('gift'), throwsA(isA<DatabaseException>()));
      expect(await addRule(EntryKindValues.saved), greaterThan(0));
      await expectLater(addRule(EntryKindValues.cardPaid), throwsA(isA<DatabaseException>()));
      expect(await addRule(EntryKindValues.spent, mode: AmountModeValues.varies), greaterThan(0));
      await expectLater(addRule(EntryKindValues.spent, mode: 'weekly'), throwsA(isA<DatabaseException>()));
    });

    test('recurring_skips holds one row per rule and date', () async {
      final int id = await db().insert(Tables.recurring, rule(id: 5, kind: EntryKindValues.spent, categoryId: 4));
      Future<int> skip() => db().insert(Tables.recurringSkips,
          <String, Object?>{RecurringSkipColumns.recurringId: id, RecurringSkipColumns.date: '2026-11-05'});
      expect(await skip(), greaterThan(0));
      await expectLater(skip(), throwsA(isA<DatabaseException>()));
    });

    test('hidden categories are seeded but never listed', () async {
      final List<Map<String, Object?>> hidden = await db().query(Tables.categories, where: '${CategoryColumns.archived} = 1');
      expect(hidden.map((Map<String, Object?> r) => r[CategoryColumns.key]), <String>['saved', 'card_paid', 'not_logged', 'not_logged_in']);
      expect(await db().query(Tables.categories, where: '${CategoryColumns.archived} = 0'), hasLength(10));
      expect('saved', CategoryKeys.saved);
    });

    test('keep aside becomes a Keep aside saving on payday', () async {
      final String path = await oldFile(1, (Database db) async {
        await db.insert(Tables.recurring, rule(id: 1, kind: EntryKindValues.got, categoryId: 9, label: 'Salary', income: true));
        await keepAside(db, '500000');
      });
      final AppDatabase upgraded = await _openOrFail(path);
      addTearDown(upgraded.close);
      final Map<String, Object?> saving =
          (await upgraded.db.query(Tables.recurring, where: "${RecurringColumns.kind} = 'save'")).single;
      final int savedId = (await upgraded.db.query(Tables.categories, where: "${CategoryColumns.key} = 'saved'")).single[CategoryColumns.id]! as int;
      expect(saving[RecurringColumns.label], 'Keep aside');
      expect(saving[RecurringColumns.amountMinor], 500000);
      expect(saving[RecurringColumns.frequency], FrequencyValues.monthly);
      expect(saving[RecurringColumns.anchorDate], '2026-10-04');
      expect(saving[RecurringColumns.nextDue], '2026-11-04');
      expect(saving[RecurringColumns.lastDayOfMonth], 0);
      expect(saving[RecurringColumns.categoryId], savedId);
      expect(await upgraded.db.query(Tables.settings, where: "${SettingsColumns.key} = '${SettingKeys.keepAsideMinor}'"), isEmpty);
    });

    test('keep aside with no monthly income goes in on the 1st', () async {
      final String path = await oldFile(1, (Database db) => keepAside(db, '200000'));
      final AppDatabase upgraded = await _openOrFail(path);
      addTearDown(upgraded.close);
      final Map<String, Object?> saving =
          (await upgraded.db.query(Tables.recurring, where: "${RecurringColumns.kind} = 'save'")).single;
      final String today = (await upgraded.db.rawQuery("SELECT date('now','localtime') AS d")).single['d']! as String;
      final String nextDue = saving[RecurringColumns.nextDue]! as String;
      expect(nextDue.endsWith('-01'), isTrue);
      expect(saving[RecurringColumns.anchorDate], nextDue);
      expect(nextDue.compareTo(today), greaterThanOrEqualTo(0));
    });

    test('keep aside of zero makes no rule and is removed', () async {
      final String path = await oldFile(1, (Database db) => keepAside(db, '0'));
      final AppDatabase upgraded = await _openOrFail(path);
      addTearDown(upgraded.close);
      expect(await upgraded.db.query(Tables.recurring, where: "${RecurringColumns.kind} = 'save'"), isEmpty);
      expect(await upgraded.db.query(Tables.settings, where: "${SettingsColumns.key} = '${SettingKeys.keepAsideMinor}'"), isEmpty);
    });

    test('a failed upgrade leaves the v2 database as it was', () async {
      final String path = await oldFile(2, (Database db) async {
        await db.insert(Tables.recurring, rule(id: 2, kind: EntryKindValues.spent, categoryId: 7));
        await db.insert(Tables.transactions, entry(id: 2, kind: EntryKindValues.spent, categoryId: 7, date: '2026-10-05', recurringId: 2));
        await keepAside(db, '500000');
        await db.execute('CREATE TABLE recurring_v3 (x INTEGER)');
      });
      final Either<Failure, AppDatabase> opened =
          await AppDatabase.open(factory: databaseFactoryFfi, path: path, singleInstance: false).run();
      expect(opened.getLeft().toNullable(), isA<DatabaseFailure>());
      final Database raw = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(version: 2));
      addTearDown(raw.close);
      expect((await raw.rawQuery('PRAGMA user_version')).single.values.single, 2);
      expect((await raw.query(Tables.transactions)).single[TransactionColumns.recurringId], 2);
      expect(await raw.query(Tables.recurring), hasLength(1));
      expect(await raw.query(Tables.settings, where: "${SettingsColumns.key} = '${SettingKeys.keepAsideMinor}'"), hasLength(1));
    });
  });

  group('Schema v4 (D153)', () {
    Future<String> v3File(Future<void> Function(Database db) fill) async {
      final Directory dir = await Directory.systemTemp.createTemp('hisaab_db_v3');
      addTearDown(() => dir.delete(recursive: true));
      final String path = p.join(dir.path, AppDatabase.fileName);
      final Database old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (Database db, int _) => runMigrations(db, from: 0, to: 3),
        ),
      );
      await fill(old);
      await old.close();
      return path;
    }

    Future<void> ruleAndTwoEntries(Database db) async {
      await db.insert(Tables.recurring, <String, Object?>{
        RecurringColumns.id: 2,
        RecurringColumns.label: 'Rent',
        RecurringColumns.amountMinor: 820000,
        RecurringColumns.kind: EntryKindValues.spent,
        RecurringColumns.categoryId: 7,
        RecurringColumns.frequency: FrequencyValues.monthly,
        RecurringColumns.anchorDate: '2026-10-05',
        RecurringColumns.nextDue: '2026-11-05',
      });
      await db.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.id: 2,
        TransactionColumns.amountMinor: 820000,
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: 7,
        TransactionColumns.date: '2026-10-05',
        TransactionColumns.recurringId: 2,
        TransactionColumns.createdAt: '2026-10-05T00:01:00.000',
      });
      await db.insert(Tables.transactions, <String, Object?>{
        TransactionColumns.id: 3,
        TransactionColumns.amountMinor: 2000,
        TransactionColumns.kind: EntryKindValues.spent,
        TransactionColumns.categoryId: 1,
        TransactionColumns.date: '2026-10-26',
        TransactionColumns.createdAt: '2026-10-26T10:05:00.000',
      });
    }

    test('a new database has an empty suggestion_state', () async {
      expect(await db().query(Tables.suggestionState), isEmpty);
    });

    test('upgrading a v3 database keeps every row and adds suggestion_state', () async {
      final String path = await v3File(ruleAndTwoEntries);
      final AppDatabase upgraded = await _openOrFail(path);
      addTearDown(upgraded.close);
      final Database db = upgraded.db;
      expect((await db.rawQuery('PRAGMA user_version')).single.values.single, 5);
      final List<Map<String, Object?>> entries = await db.query(Tables.transactions, orderBy: TransactionColumns.id);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.id]), <int>[2, 3]);
      expect(entries.map((Map<String, Object?> e) => e[TransactionColumns.recurringId]), <int?>[2, null]);
      expect(
        entries.map((Map<String, Object?> e) => e[TransactionColumns.createdAt]),
        <String>['2026-10-05T00:01:00.000', '2026-10-26T10:05:00.000'],
      );
      expect((await db.query(Tables.recurring)).single[RecurringColumns.label], 'Rent');
      expect(await db.query(Tables.categories), hasLength(14));
      expect(await db.query(Tables.suggestionState), isEmpty);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    });

    test('suggestion_state holds one row per category and goes with its category', () async {
      final int categoryId = await db().insert(Tables.categories, <String, Object?>{
        CategoryColumns.key: 'own_13',
        CategoryColumns.customName: 'Chai',
        CategoryColumns.iconKey: 'chai',
        CategoryColumns.kind: EntryKindValues.spent,
        CategoryColumns.sort: 8,
      });
      Future<int> quiet() => db().insert(Tables.suggestionState, <String, Object?>{
            SuggestionStateColumns.categoryId: categoryId,
            SuggestionStateColumns.quietOn: '2026-10-26',
          });
      expect(await quiet(), greaterThan(0));
      await expectLater(quiet(), throwsA(isA<DatabaseException>()));

      await db().delete(Tables.categories, where: '${CategoryColumns.id} = ?', whereArgs: <Object?>[categoryId]);

      expect(await db().query(Tables.suggestionState), isEmpty);
    });

    test('suggestion_state refuses a category that does not exist', () async {
      await expectLater(
        db().insert(Tables.suggestionState, <String, Object?>{SuggestionStateColumns.categoryId: 999}),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('a failed upgrade leaves the v3 database as it was', () async {
      final String path = await v3File((Database db) async {
        await ruleAndTwoEntries(db);
        await db.execute('CREATE TABLE suggestion_state (x INTEGER)');
      });
      final Either<Failure, AppDatabase> opened =
          await AppDatabase.open(factory: databaseFactoryFfi, path: path, singleInstance: false).run();
      expect(opened.getLeft().toNullable(), isA<DatabaseFailure>());
      final Database raw = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(version: 3));
      addTearDown(raw.close);
      expect((await raw.rawQuery('PRAGMA user_version')).single.values.single, 3);
      expect(await raw.query(Tables.transactions), hasLength(2));
      expect(await raw.query(Tables.recurring), hasLength(1));
      expect((await raw.rawQuery('PRAGMA table_info(suggestion_state)')).single['name'], 'x');
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
      expect(await second.db.query(Tables.categories), hasLength(14));
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
