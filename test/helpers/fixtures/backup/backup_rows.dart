import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Seeds a finished-onboarding database: an income rule, an inactive bill, and one entry with a
/// note, so a backup carries every kind of row (SPEC NFR-5). Works on schema v1 and later.
Future<void> seedMoney(DatabaseExecutor db) async {
  await db.insert(Tables.recurring, <String, Object?>{
    RecurringColumns.id: 1,
    RecurringColumns.label: 'Salary',
    RecurringColumns.amountMinor: 4500000,
    RecurringColumns.kind: 'in',
    RecurringColumns.categoryId: 1,
    RecurringColumns.frequency: 'monthly',
    RecurringColumns.anchorDate: '2026-10-04',
    RecurringColumns.nextDue: '2026-11-04',
    RecurringColumns.isIncomeSource: 1,
  });
  await db.insert(Tables.recurring, <String, Object?>{
    RecurringColumns.id: 2,
    RecurringColumns.label: 'Old gym',
    RecurringColumns.amountMinor: 100000,
    RecurringColumns.kind: 'out',
    RecurringColumns.categoryId: 1,
    RecurringColumns.frequency: 'monthly',
    RecurringColumns.anchorDate: '2026-01-04',
    RecurringColumns.nextDue: '2026-02-04',
    RecurringColumns.active: 0,
  });
  await db.insert(Tables.transactions, <String, Object?>{
    TransactionColumns.id: 7,
    TransactionColumns.amountMinor: 12000,
    TransactionColumns.kind: 'out',
    TransactionColumns.categoryId: 1,
    TransactionColumns.date: '2026-11-05',
    TransactionColumns.note: 'chai ☕ with Ravi',
    TransactionColumns.createdAt: '2026-11-05T09:30:00.000',
  });
  await db.insert(Tables.settings, <String, Object?>{SettingsColumns.key: SettingKeys.onboardingDone, SettingsColumns.value: '1'});
}

