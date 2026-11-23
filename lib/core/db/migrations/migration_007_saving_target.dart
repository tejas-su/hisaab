import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v7: an optional target on a saving and the memory of the last one it reached (SPEC BR-23).
///
/// All three columns are null on every existing row, which means "no target".
Future<void> migration007SavingTarget(DatabaseExecutor db) async {
  await db.execute(
    'ALTER TABLE ${Tables.recurring} ADD COLUMN ${RecurringColumns.targetMinor} INTEGER '
    'CHECK (${RecurringColumns.targetMinor} IS NULL OR ${RecurringColumns.targetMinor} > 0)',
  );
  await db.execute('ALTER TABLE ${Tables.recurring} ADD COLUMN ${RecurringColumns.targetReachedFor} INTEGER');
  await db.execute('ALTER TABLE ${Tables.recurring} ADD COLUMN ${RecurringColumns.targetReachedOn} TEXT');
}
