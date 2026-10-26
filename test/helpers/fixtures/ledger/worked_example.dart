import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';

import 'categories.dart';

/// The SPEC BR-4 / BR-7 worked example as ledger data: payday on the 4th, today Mon 26 Oct 2026.
abstract final class WorkedExample {
  static const CalendarDate today = CalendarDate(2026, 10, 26);
  static final DateTime now = DateTime(2026, 10, 26, 10, 30);

  static final RecurringRule salary = RecurringRule(
    id: 1,
    label: 'Salary',
    amount: Money.fromMajor(45000),
    kind: EntryKind.got,
    categoryId: SeedCategoryIds.salary,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 4)),
    nextDue: const CalendarDate(2026, 11, 4),
    isIncomeSource: true,
  );

  static final RecurringRule rent = RecurringRule(
    id: 2,
    label: 'Rent',
    amount: Money.fromMajor(8200),
    kind: EntryKind.spent,
    categoryId: SeedCategoryIds.home,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 5)),
    nextDue: const CalendarDate(2026, 11, 5),
  );

  static final RecurringRule electricity = RecurringRule(
    id: 3,
    label: 'Electricity',
    amount: Money.fromMajor(1200),
    kind: EntryKind.spent,
    categoryId: SeedCategoryIds.bills,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 29)),
    nextDue: const CalendarDate(2026, 10, 29),
  );

  static List<RecurringRule> get rules => <RecurringRule>[salary, rent, electricity];

  /// I = ₹45,000; S_prev = ₹27,150 (₹8,200 rent + ₹18,950 typed); S_today = ₹420.
  static List<Entry> get entries => <Entry>[
        _entry(1, 45000, EntryKind.got, SeedCategoryIds.salary, const CalendarDate(2026, 10, 4), recurringId: 1),
        _entry(2, 8200, EntryKind.spent, SeedCategoryIds.home, const CalendarDate(2026, 10, 5), recurringId: 2),
        _entry(3, 18950, EntryKind.spent, SeedCategoryIds.food, const CalendarDate(2026, 10, 20)),
        _entry(4, 60, EntryKind.spent, SeedCategoryIds.food, today, note: 'Chai & samosa'),
        _entry(5, 120, EntryKind.spent, SeedCategoryIds.travel, today, note: 'Auto to office'),
        _entry(6, 240, EntryKind.spent, 3, today, note: 'Groceries'),
      ];

  static Entry _entry(int id, int rupees, EntryKind kind, int categoryId, CalendarDate date,
          {int? recurringId, String? note}) =>
      Entry(
        id: id,
        amount: Money.fromMajor(rupees),
        kind: kind,
        categoryId: categoryId,
        date: date,
        note: note,
        recurringId: recurringId,
      );
}
