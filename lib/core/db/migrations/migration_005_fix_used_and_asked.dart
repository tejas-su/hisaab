import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v5: the *Used* kind with its saving link, the two hidden *Not logged* categories and the
/// day a habit question was asked (SPEC BR-19, BR-11, BR-17, D191).
///
/// Three features share one migration so the backup version moves once, from 4 to 5. SQLite can't
/// widen a `CHECK`, so `transactions` is rebuilt with its ids, as migration 003 did. The other two
/// parts are additive: two archived category rows and a nullable column that stays empty until used.
Future<void> migration005FixUsedAndAsked(DatabaseExecutor db) async {
  await _seedNotLoggedCategories(db);
  for (final String statement in _rebuildTransactions) {
    await db.execute(statement);
  }
  await db.execute('ALTER TABLE ${Tables.suggestionState} ADD COLUMN ${SuggestionStateColumns.askedOn} TEXT');
}

// why: core can't import the ledger feature, so the keys are spelled here; a test pins both to
// `CategoryKeys.notLogged` and `CategoryKeys.notLoggedIn`.
const String _notLoggedKey = 'not_logged';
const String _notLoggedInKey = 'not_logged_in';

Future<void> _seedNotLoggedCategories(DatabaseExecutor db) async {
  await _insertHidden(db, _notLoggedKey, EntryKindValues.spent);
  await _insertHidden(db, _notLoggedInKey, EntryKindValues.got);
}

Future<void> _insertHidden(DatabaseExecutor db, String key, String kind) async {
  final List<Map<String, Object?>> existing =
      await db.query(Tables.categories, where: '${CategoryColumns.key} = ?', whereArgs: <Object?>[key]);
  if (existing.isNotEmpty) {
    return;
  }
  final Object? highest = (await db.rawQuery(
    'SELECT MAX(${CategoryColumns.sort}) AS highest FROM ${Tables.categories} WHERE ${CategoryColumns.kind} = ?',
    <Object?>[kind],
  ))
      .single['highest'];
  await db.insert(Tables.categories, <String, Object?>{
    CategoryColumns.key: key,
    CategoryColumns.iconKey: key,
    CategoryColumns.kind: kind,
    CategoryColumns.sort: highest is int ? highest + 1 : 0,
    CategoryColumns.archived: 1,
  });
}

const String _transactionsV5 = 'transactions_v5';

const String _carriedColumns = '${TransactionColumns.id}, ${TransactionColumns.amountMinor}, '
    '${TransactionColumns.currency}, ${TransactionColumns.kind}, ${TransactionColumns.categoryId}, '
    '${TransactionColumns.date}, ${TransactionColumns.note}, ${TransactionColumns.recurringId}, ${TransactionColumns.createdAt}';

const List<String> _rebuildTransactions = <String>[
  '''
  CREATE TABLE $_transactionsV5 (
    ${TransactionColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
    ${TransactionColumns.amountMinor} INTEGER NOT NULL CHECK (${TransactionColumns.amountMinor} > 0),
    ${TransactionColumns.currency} TEXT NOT NULL DEFAULT 'INR',
    ${TransactionColumns.kind} TEXT NOT NULL CHECK (${TransactionColumns.kind} IN ('out', 'in', 'save', 'card', 'used')),
    ${TransactionColumns.categoryId} INTEGER NOT NULL REFERENCES ${Tables.categories}(${CategoryColumns.id}),
    ${TransactionColumns.date} TEXT NOT NULL,
    ${TransactionColumns.note} TEXT CHECK (${TransactionColumns.note} IS NULL OR length(${TransactionColumns.note}) <= 80),
    ${TransactionColumns.recurringId} INTEGER REFERENCES ${Tables.recurring}(${RecurringColumns.id}) ON DELETE SET NULL,
    ${TransactionColumns.createdAt} TEXT NOT NULL,
    ${TransactionColumns.savingId} INTEGER REFERENCES ${Tables.recurring}(${RecurringColumns.id}) ON DELETE SET NULL
  )''',
  'INSERT INTO $_transactionsV5 ($_carriedColumns) SELECT $_carriedColumns FROM ${Tables.transactions}',
  // why: nothing references `transactions`, so it can be dropped at once; the rows are already
  // copied, and its three indexes go with it and are recreated below.
  'DROP TABLE ${Tables.transactions}',
  'ALTER TABLE $_transactionsV5 RENAME TO ${Tables.transactions}',
  'CREATE INDEX ix_transactions_date ON ${Tables.transactions}(${TransactionColumns.date})',
  '''
  CREATE INDEX ix_transactions_category_date
  ON ${Tables.transactions}(${TransactionColumns.categoryId}, ${TransactionColumns.date})''',
  // why: the unique index is on the rule link only, so a *Used* entry (linked by `saving_id`) may
  // share a date with a put-in of the same saving (BR-9, D175).
  '''
  CREATE UNIQUE INDEX ux_transactions_recurring_date
  ON ${Tables.transactions}(${TransactionColumns.recurringId}, ${TransactionColumns.date})''',
  'CREATE INDEX ix_transactions_saving ON ${Tables.transactions}(${TransactionColumns.savingId})',
];
