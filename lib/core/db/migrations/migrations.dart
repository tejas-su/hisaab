import 'package:sqflite/sqflite.dart';

import 'migration_001_initial.dart';
import 'migration_002_bill_icon.dart';
import 'migration_003_savings_and_changing_bills.dart';

/// One schema step; migration `n` upgrades the database from version `n - 1` to `n`.
typedef Migration = Future<void> Function(DatabaseExecutor db);

/// Every migration in order. Append new ones; never edit or reorder shipped entries.
const List<Migration> migrations = <Migration>[
  migration001Initial,
  migration002BillIcon,
  migration003SavingsAndChangingBills,
];

/// Runs the migrations that take a database from version [from] to version [to].
Future<void> runMigrations(DatabaseExecutor db, {required int from, required int to}) async {
  for (final Migration migration in migrations.sublist(from, to)) {
    await migration(db);
  }
}
