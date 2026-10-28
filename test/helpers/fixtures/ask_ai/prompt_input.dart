import 'package:expense_tracker/ask_ai/domain/entities/prompt_input.dart';
import 'package:expense_tracker/core/money/money.dart';
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
  Option<CycleSummary> summary = const Option<CycleSummary>.none(),
  Money keepAside = Money.zero,
  CalendarDate today = WorkedExample.today,
}) => PromptInput(
  cycles: workedCycles,
  today: today,
  incomeRule: incomeRule ?? Option<RecurringRule>.of(WorkedExample.salary),
  payRule: payRule,
  bills: bills ?? <RecurringRule>[WorkedExample.rent, WorkedExample.electricity],
  categories: categories,
  entries: entries ?? WorkedExample.entries,
  summary: summary,
  keepAside: keepAside,
);

/// Home's summary for the worked example (SPEC BR-4, BR-7): ₹1,430 safe today, about ₹9,300 spare.
CycleSummary workedSummary({CycleState state = const OnTrack(), RangeForecast forecast = const LastsTillPayday(Money(930000))}) =>
    CycleSummary(
      cycle: workedCycles.first,
      today: WorkedExample.today,
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(1850),
      spentToday: Money.fromMajor(420),
      tomorrowShare: Option<Money>.of(Money.fromMajor(2027)),
      state: state,
      forecast: forecast,
      earliestEntryDate: workedCycles[1].start,
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
