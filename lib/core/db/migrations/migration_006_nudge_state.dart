import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v6: what the daily nudge remembers, per category or for the general nudge (SPEC BR-22.12).
///
/// `category_id` 0 is the general nudge, so the column has no foreign key.
Future<void> migration006NudgeState(DatabaseExecutor db) => db.execute('''
CREATE TABLE ${Tables.nudgeState} (
  ${NudgeStateColumns.categoryId} INTEGER PRIMARY KEY,
  ${NudgeStateColumns.armedFor} TEXT,
  ${NudgeStateColumns.ignoredStreak} INTEGER NOT NULL DEFAULT 0,
  ${NudgeStateColumns.restUntil} TEXT
)''');
