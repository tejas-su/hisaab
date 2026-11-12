import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v4: the quiet, rest and forget state of each category's *your usual* (SPEC BR-17, D153).
///
/// A row goes with its category. Categories are never deleted in the app, only archived, so the
/// cascade fires only when a restore or *Delete everything* empties `categories`.
Future<void> migration004SuggestionState(DatabaseExecutor db) => db.execute('''
CREATE TABLE ${Tables.suggestionState} (
  ${SuggestionStateColumns.categoryId} INTEGER PRIMARY KEY
    REFERENCES ${Tables.categories}(${CategoryColumns.id}) ON DELETE CASCADE,
  ${SuggestionStateColumns.quietOn} TEXT,
  ${SuggestionStateColumns.restUntil} TEXT,
  ${SuggestionStateColumns.forgottenAt} TEXT
)''');
