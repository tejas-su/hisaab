import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

/// Schema v2: an optional picked icon per recurring rule; existing rules keep none (D118).
Future<void> migration002BillIcon(DatabaseExecutor db) =>
    db.execute('ALTER TABLE ${Tables.recurring} ADD COLUMN ${RecurringColumns.icon} TEXT');
