import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v3: saved and card-bill kinds, `amount_mode`, `recurring_skips`, hidden categories, and
/// the keep-aside setting moved to a saving rule (D120).
///
/// SQLite can't widen a `CHECK`, so `recurring` and `transactions` are rebuilt with their ids.
/// The columns for changing bills ship now so the next phase needs no schema bump.
Future<void> migration003SavingsAndChangingBills(DatabaseExecutor db) async {
  for (final String statement in _rebuild) {
    await db.execute(statement);
  }
  await _seedHiddenCategories(db);
  await _moveKeepAsideToSaving(db);
}

const String _recurringV3 = 'recurring_v3';
const String _transactionsV3 = 'transactions_v3';

const String _recurringColumns = '${RecurringColumns.id}, ${RecurringColumns.label}, ${RecurringColumns.amountMinor}, '
    '${RecurringColumns.currency}, ${RecurringColumns.kind}, ${RecurringColumns.categoryId}, ${RecurringColumns.frequency}, '
    '${RecurringColumns.anchorDate}, ${RecurringColumns.lastDayOfMonth}, ${RecurringColumns.nextDue}, '
    '${RecurringColumns.active}, ${RecurringColumns.isIncomeSource}, ${RecurringColumns.icon}';

const String _transactionColumns = '${TransactionColumns.id}, ${TransactionColumns.amountMinor}, '
    '${TransactionColumns.currency}, ${TransactionColumns.kind}, ${TransactionColumns.categoryId}, '
    '${TransactionColumns.date}, ${TransactionColumns.note}, ${TransactionColumns.recurringId}, ${TransactionColumns.createdAt}';

const List<String> _rebuild = <String>[
  '''
  CREATE TABLE $_recurringV3 (
    ${RecurringColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
    ${RecurringColumns.label} TEXT NOT NULL,
    ${RecurringColumns.amountMinor} INTEGER NOT NULL CHECK (${RecurringColumns.amountMinor} > 0),
    ${RecurringColumns.currency} TEXT NOT NULL DEFAULT 'INR',
    ${RecurringColumns.kind} TEXT NOT NULL CHECK (${RecurringColumns.kind} IN ('out', 'in', 'save')),
    ${RecurringColumns.categoryId} INTEGER NOT NULL REFERENCES ${Tables.categories}(${CategoryColumns.id}),
    ${RecurringColumns.frequency} TEXT NOT NULL CHECK (${RecurringColumns.frequency} IN ('weekly', 'biweekly', 'monthly', 'yearly')),
    ${RecurringColumns.anchorDate} TEXT NOT NULL,
    ${RecurringColumns.lastDayOfMonth} INTEGER NOT NULL DEFAULT 0 CHECK (${RecurringColumns.lastDayOfMonth} IN (0, 1)),
    ${RecurringColumns.nextDue} TEXT NOT NULL,
    ${RecurringColumns.active} INTEGER NOT NULL DEFAULT 1 CHECK (${RecurringColumns.active} IN (0, 1)),
    ${RecurringColumns.isIncomeSource} INTEGER NOT NULL DEFAULT 0 CHECK (${RecurringColumns.isIncomeSource} IN (0, 1)),
    ${RecurringColumns.icon} TEXT,
    ${RecurringColumns.amountMode} TEXT NOT NULL DEFAULT 'fixed'
      CHECK (${RecurringColumns.amountMode} IN ('fixed', 'varies', 'card'))
  )''',
  'INSERT INTO $_recurringV3 ($_recurringColumns) SELECT $_recurringColumns FROM ${Tables.recurring}',
  '''
  CREATE TABLE $_transactionsV3 (
    ${TransactionColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
    ${TransactionColumns.amountMinor} INTEGER NOT NULL CHECK (${TransactionColumns.amountMinor} > 0),
    ${TransactionColumns.currency} TEXT NOT NULL DEFAULT 'INR',
    ${TransactionColumns.kind} TEXT NOT NULL CHECK (${TransactionColumns.kind} IN ('out', 'in', 'save', 'card')),
    ${TransactionColumns.categoryId} INTEGER NOT NULL REFERENCES ${Tables.categories}(${CategoryColumns.id}),
    ${TransactionColumns.date} TEXT NOT NULL,
    ${TransactionColumns.note} TEXT CHECK (${TransactionColumns.note} IS NULL OR length(${TransactionColumns.note}) <= 80),
    ${TransactionColumns.recurringId} INTEGER REFERENCES $_recurringV3(${RecurringColumns.id}) ON DELETE SET NULL,
    ${TransactionColumns.createdAt} TEXT NOT NULL
  )''',
  'INSERT INTO $_transactionsV3 ($_transactionColumns) SELECT $_transactionColumns FROM ${Tables.transactions}',
  // why: the child goes first. Dropping a parent runs an implicit DELETE, which would fire
  // ON DELETE SET NULL on every live link and turn posted bills into typed spending.
  'DROP TABLE ${Tables.transactions}',
  'DROP TABLE ${Tables.recurring}',
  'ALTER TABLE $_recurringV3 RENAME TO ${Tables.recurring}',
  'ALTER TABLE $_transactionsV3 RENAME TO ${Tables.transactions}',
  '''
  CREATE UNIQUE INDEX ux_recurring_one_income_source ON ${Tables.recurring}(${RecurringColumns.isIncomeSource})
  WHERE ${RecurringColumns.isIncomeSource} = 1 AND ${RecurringColumns.active} = 1''',
  'CREATE INDEX ix_transactions_date ON ${Tables.transactions}(${TransactionColumns.date})',
  '''
  CREATE INDEX ix_transactions_category_date
  ON ${Tables.transactions}(${TransactionColumns.categoryId}, ${TransactionColumns.date})''',
  '''
  CREATE UNIQUE INDEX ux_transactions_recurring_date
  ON ${Tables.transactions}(${TransactionColumns.recurringId}, ${TransactionColumns.date})''',
  // why: starting fresh deletes rules, so their skips must go with them.
  '''
  CREATE TABLE ${Tables.recurringSkips} (
    ${RecurringSkipColumns.recurringId} INTEGER NOT NULL REFERENCES ${Tables.recurring}(${RecurringColumns.id}) ON DELETE CASCADE,
    ${RecurringSkipColumns.date} TEXT NOT NULL,
    PRIMARY KEY (${RecurringSkipColumns.recurringId}, ${RecurringSkipColumns.date})
  )''',
];

// why: core can't import the ledger feature, so the keys are spelled here; a test pins
// `'saved'` to `CategoryKeys.saved`.
const String _savedKey = 'saved';
const List<String> _hiddenKeys = <String>[_savedKey, 'card_paid'];

Future<void> _seedHiddenCategories(DatabaseExecutor db) async {
  for (final (int index, String key) in _hiddenKeys.indexed) {
    await db.insert(Tables.categories, <String, Object?>{
      CategoryColumns.key: key,
      CategoryColumns.iconKey: key,
      CategoryColumns.kind: EntryKindValues.spent,
      CategoryColumns.sort: index,
      CategoryColumns.archived: 1,
    });
  }
}

Future<void> _moveKeepAsideToSaving(DatabaseExecutor db) async {
  final List<Map<String, Object?>> setting = await db.query(
    Tables.settings,
    where: '${SettingsColumns.key} = ?',
    whereArgs: <Object?>[SettingKeys.keepAsideMinor],
  );
  final Object? value = setting.isEmpty ? null : setting.single[SettingsColumns.value];
  final int amountMinor = value is String ? int.tryParse(value) ?? 0 : 0;
  if (amountMinor > 0) {
    await db.insert(Tables.recurring, <String, Object?>{
      // why: stored data, like the onboarding labels; no ARB string ever reaches the database.
      RecurringColumns.label: 'Keep aside',
      RecurringColumns.amountMinor: amountMinor,
      RecurringColumns.kind: EntryKindValues.saved,
      RecurringColumns.categoryId: await _categoryId(db, _savedKey),
      RecurringColumns.frequency: FrequencyValues.monthly,
      ...await _payday(db),
    });
  }
  await db.delete(Tables.settings, where: '${SettingsColumns.key} = ?', whereArgs: <Object?>[SettingKeys.keepAsideMinor]);
}

Future<int> _categoryId(DatabaseExecutor db, String key) async {
  final Object? id = (await db.query(Tables.categories, where: '${CategoryColumns.key} = ?', whereArgs: <Object?>[key]))
      .single[CategoryColumns.id];
  return id is int ? id : throw StateError('Category "$key" has no id');
}

// why: the next payday the engine hasn't posted keeps D33 (no back-post). Without a monthly
// income rule the saving goes in on the 1st; DI doesn't exist yet, so SQLite's clock is used.
Future<Map<String, Object?>> _payday(DatabaseExecutor db) async {
  final List<Map<String, Object?>> income = await db.query(
    Tables.recurring,
    columns: <String>[RecurringColumns.anchorDate, RecurringColumns.lastDayOfMonth, RecurringColumns.nextDue],
    where: '${RecurringColumns.isIncomeSource} = 1 AND ${RecurringColumns.active} = 1 AND ${RecurringColumns.frequency} = ?',
    whereArgs: <Object?>[FrequencyValues.monthly],
  );
  if (income.isNotEmpty) {
    return income.single;
  }
  final Object? first = (await db.rawQuery(
    "SELECT CASE WHEN strftime('%d','now','localtime') = '01' THEN date('now','localtime') "
    "ELSE date('now','localtime','start of month','+1 month') END AS first",
  ))
      .single['first'];
  return <String, Object?>{RecurringColumns.anchorDate: first, RecurringColumns.nextDue: first};
}
