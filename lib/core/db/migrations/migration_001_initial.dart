import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v1: categories, recurring rules, entries, settings, plus seed data (SPEC BR-11).
///
/// Shipped migrations are never edited; later changes get a new migration file.
Future<void> migration001Initial(DatabaseExecutor db) async {
  for (final String statement in _schema) {
    await db.execute(statement);
  }
  await _seedCategories(db);
  await _seedSettings(db);
}

const List<String> _schema = <String>[
  '''
  CREATE TABLE ${Tables.categories} (
    ${CategoryColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CategoryColumns.key} TEXT NOT NULL UNIQUE,
    ${CategoryColumns.customName} TEXT,
    ${CategoryColumns.iconKey} TEXT NOT NULL,
    ${CategoryColumns.kind} TEXT NOT NULL CHECK (${CategoryColumns.kind} IN ('out', 'in')),
    ${CategoryColumns.budgetMinor} INTEGER CHECK (${CategoryColumns.budgetMinor} IS NULL OR ${CategoryColumns.budgetMinor} > 0),
    ${CategoryColumns.sort} INTEGER NOT NULL,
    ${CategoryColumns.archived} INTEGER NOT NULL DEFAULT 0 CHECK (${CategoryColumns.archived} IN (0, 1))
  )''',
  '''
  CREATE TABLE ${Tables.recurring} (
    ${RecurringColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
    ${RecurringColumns.label} TEXT NOT NULL,
    ${RecurringColumns.amountMinor} INTEGER NOT NULL CHECK (${RecurringColumns.amountMinor} > 0),
    ${RecurringColumns.currency} TEXT NOT NULL DEFAULT 'INR',
    ${RecurringColumns.kind} TEXT NOT NULL CHECK (${RecurringColumns.kind} IN ('out', 'in')),
    ${RecurringColumns.categoryId} INTEGER NOT NULL REFERENCES ${Tables.categories}(${CategoryColumns.id}),
    ${RecurringColumns.frequency} TEXT NOT NULL CHECK (${RecurringColumns.frequency} IN ('weekly', 'biweekly', 'monthly', 'yearly')),
    ${RecurringColumns.anchorDate} TEXT NOT NULL,
    ${RecurringColumns.lastDayOfMonth} INTEGER NOT NULL DEFAULT 0 CHECK (${RecurringColumns.lastDayOfMonth} IN (0, 1)),
    ${RecurringColumns.nextDue} TEXT NOT NULL,
    ${RecurringColumns.active} INTEGER NOT NULL DEFAULT 1 CHECK (${RecurringColumns.active} IN (0, 1)),
    ${RecurringColumns.isIncomeSource} INTEGER NOT NULL DEFAULT 0 CHECK (${RecurringColumns.isIncomeSource} IN (0, 1))
  )''',
  '''
  CREATE UNIQUE INDEX ux_recurring_one_income_source ON ${Tables.recurring}(${RecurringColumns.isIncomeSource})
  WHERE ${RecurringColumns.isIncomeSource} = 1 AND ${RecurringColumns.active} = 1''',
  '''
  CREATE TABLE ${Tables.transactions} (
    ${TransactionColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
    ${TransactionColumns.amountMinor} INTEGER NOT NULL CHECK (${TransactionColumns.amountMinor} > 0),
    ${TransactionColumns.currency} TEXT NOT NULL DEFAULT 'INR',
    ${TransactionColumns.kind} TEXT NOT NULL CHECK (${TransactionColumns.kind} IN ('out', 'in')),
    ${TransactionColumns.categoryId} INTEGER NOT NULL REFERENCES ${Tables.categories}(${CategoryColumns.id}),
    ${TransactionColumns.date} TEXT NOT NULL,
    ${TransactionColumns.note} TEXT CHECK (${TransactionColumns.note} IS NULL OR length(${TransactionColumns.note}) <= 80),
    ${TransactionColumns.recurringId} INTEGER REFERENCES ${Tables.recurring}(${RecurringColumns.id}) ON DELETE SET NULL,
    ${TransactionColumns.createdAt} TEXT NOT NULL
  )''',
  'CREATE INDEX ix_transactions_date ON ${Tables.transactions}(${TransactionColumns.date})',
  '''
  CREATE INDEX ix_transactions_category_date
  ON ${Tables.transactions}(${TransactionColumns.categoryId}, ${TransactionColumns.date})''',
  // why: makes recurring posting idempotent (SPEC BR-9); SQLite treats NULL recurring_ids
  // as distinct, so manual entries are unaffected.
  '''
  CREATE UNIQUE INDEX ux_transactions_recurring_date
  ON ${Tables.transactions}(${TransactionColumns.recurringId}, ${TransactionColumns.date})''',
  '''
  CREATE TABLE ${Tables.settings} (
    ${SettingsColumns.key} TEXT PRIMARY KEY,
    ${SettingsColumns.value} TEXT NOT NULL
  )''',
];

const List<String> _spentCategoryKeys = <String>[
  'food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other', //
];
const List<String> _gotCategoryKeys = <String>['salary', 'other_income'];

Future<void> _seedCategories(DatabaseExecutor db) async {
  Future<void> seed(List<String> keys, String kind) async {
    for (final (int index, String key) in keys.indexed) {
      await db.insert(Tables.categories, <String, Object?>{
        CategoryColumns.key: key,
        CategoryColumns.iconKey: key,
        CategoryColumns.kind: kind,
        CategoryColumns.sort: index,
      });
    }
  }

  await seed(_spentCategoryKeys, EntryKindValues.spent);
  await seed(_gotCategoryKeys, EntryKindValues.got);
}

Future<void> _seedSettings(DatabaseExecutor db) async {
  const Map<String, String> defaults = <String, String>{
    SettingKeys.currency: 'INR',
    SettingKeys.monthStart: 'payday',
  };
  for (final MapEntry<String, String> entry in defaults.entries) {
    await db.insert(Tables.settings, <String, Object?>{
      SettingsColumns.key: entry.key,
      SettingsColumns.value: entry.value,
    });
  }
}
