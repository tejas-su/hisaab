import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/pay_rule.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';

/// The income's words for Settings and the income sheet (SPEC FR-SE-1, D137, D140).
extension IncomeCopy on BuildContext {
  /// The second line of the *Money coming in* row: "₹45,000 · on day 4", or "Changes each month".
  String incomeRowValue(Income income) {
    final AppLocalizations strings = AppLocalizations.of(this);
    return income.rule.match(
      () => strings.incomeRowIrregular,
      (RecurringRule rule) {
        final String amount = money.format(IncomeAmount.monthlyOf(rule));
        return switch (PayRuleSchedule.payRuleOf(income.rule)) {
          MonthlyOnDay(:final int day) => strings.incomeRowMonthly(amount, day),
          LastDayOfMonth() => strings.incomeRowLastDay(amount),
          WeeklyOn(:final int weekday) => strings.incomeRowWeekly(amount, weekdayName(weekday)),
          IrregularIncome() => strings.incomeRowIrregular,
        };
      },
    );
  }

  /// The line under the amount on the slip: when the money comes, with the week's pay for weekly.
  String incomeComes(RecurringRule rule) {
    final PayRule payRule = PayRuleSchedule.payRuleOf(Option<RecurringRule>.of(rule));
    return switch (payRule) {
      WeeklyOn(:final int weekday) =>
        AppLocalizations.of(this).incomeComesWeekly(weekdayName(weekday), money.format(rule.amount)),
      _ => payRuleComes(payRule),
    };
  }

  /// When [rule] says the money comes, with no amount: "Comes every month on day 4".
  String payRuleComes(PayRule rule) {
    final AppLocalizations strings = AppLocalizations.of(this);
    return switch (rule) {
      MonthlyOnDay(:final int day) => strings.incomeComesOnDay(day),
      LastDayOfMonth() => strings.incomeComesLastDay,
      WeeklyOn(:final int weekday) => strings.incomeComesEvery(weekdayName(weekday)),
      IrregularIncome() => strings.incomeIrregularEvery,
    };
  }

  /// The *When it comes* row's value for [rule]: "Day 4", "Last day", "Friday" or "It changes".
  String payRuleWhen(PayRule rule) {
    final AppLocalizations strings = AppLocalizations.of(this);
    return switch (rule) {
      MonthlyOnDay(:final int day) => strings.incomeWhenDay(day),
      LastDayOfMonth() => strings.incomeWhenLastDay,
      WeeklyOn(:final int weekday) => weekdayName(weekday),
      IrregularIncome() => strings.payItChanges,
    };
  }

  /// The ICU select value for copy that says "this week" or "this month".
  String incomePeriod(RecurringRule rule) => rule.schedule.frequency == Frequency.weekly ? 'week' : 'month';

  /// [date] as "4 Nov" in the app's locale.
  String incomeDate(CalendarDate date) =>
      DateFormat('d MMM', Localizations.localeOf(this).toString()).format(DateTime(date.year, date.month, date.day));

  /// The full name of [weekday] ([DateTime.monday] … [DateTime.sunday]) in the app's locale.
  // why: 1 Jan 2024 was a Monday, so day N of that month is weekday N.
  String weekdayName(int weekday) => DateFormat.EEEE(Localizations.localeOf(this).toString()).format(DateTime(2024, 1, weekday));
}
