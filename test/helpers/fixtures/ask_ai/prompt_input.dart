import 'package:expense_tracker/ask_ai/domain/entities/prompt_input.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:fpdart/fpdart.dart';

import '../ledger/categories.dart';
import '../ledger/worked_example.dart';

/// The worked example's cycle (4 Oct – 3 Nov 2026) and the two before it, newest first.
const List<PayCycle> workedCycles = <PayCycle>[
  PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
  PayCycle(start: CalendarDate(2026, 9, 4), end: CalendarDate(2026, 10, 3)),
  PayCycle(start: CalendarDate(2026, 8, 4), end: CalendarDate(2026, 9, 3)),
];

/// The SPEC worked example as prompt input: payday on the 4th, today Mon 26 Oct 2026.
PromptInput workedPromptInput({
  List<Entry>? entries,
  List<Category> categories = seedCategories,
  List<RecurringRule>? bills,
  Option<RecurringRule>? incomeRule,
  PayRule payRule = const MonthlyOnDay(4),
}) => PromptInput(
  cycles: workedCycles,
  today: WorkedExample.today,
  incomeRule: incomeRule ?? Option<RecurringRule>.of(WorkedExample.salary),
  payRule: payRule,
  bills: bills ?? <RecurringRule>[WorkedExample.rent, WorkedExample.electricity],
  categories: categories,
  entries: entries ?? WorkedExample.entries,
);

/// The English seed names, as `AppLocalizations.categoryName` gives them.
String englishName(Category category) =>
    category.customName ??
    const <String, String>{
      'food': 'Food',
      'travel': 'Travel',
      'shopping': 'Shopping',
      'bills': 'Bills',
      'fun': 'Fun',
      'health': 'Health',
      'home': 'Home',
      'salary': 'Salary',
      'other_income': 'Other income',
      'other': 'Other',
    }[category.key]!;
