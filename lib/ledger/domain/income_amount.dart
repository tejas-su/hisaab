import '../../core/money/money.dart';
import 'entities/frequency.dart';
import 'entities/recurring_rule.dart';
import 'entities/schedule.dart';

/// Converts between the monthly income the user types and the amount the salary rule posts
/// each payday (DECISIONS D26: the question is always "each month").
abstract final class IncomeAmount {
  static const int _weeksPerYear = 52;
  static const int _monthsPerYear = 12;

  /// The amount one payday posts for [monthly] income on [schedule]: the same for a monthly rule,
  /// the month spread over 52 weeks and floored to the rupee for a weekly one.
  static Money perPay(Money monthly, Schedule schedule) {
    if (schedule.frequency != Frequency.weekly) {
      return monthly;
    }
    final int weeklyMajor = monthly.floorMajor * _monthsPerYear ~/ _weeksPerYear;
    return Money.fromMajor(weeklyMajor, currency: monthly.currency);
  }

  /// The monthly income that [income] stands for, to prefill the amount question.
  ///
  /// A weekly rule gives the smallest month whose [perPay] is that week, so saving it unchanged
  /// writes nothing.
  static Money monthlyOf(RecurringRule income) {
    if (income.schedule.frequency != Frequency.weekly) {
      return income.amount;
    }
    final int yearMajor = income.amount.floorMajor * _weeksPerYear;
    final int monthlyMajor = (yearMajor + _monthsPerYear - 1) ~/ _monthsPerYear;
    return Money.fromMajor(monthlyMajor, currency: income.amount.currency);
  }
}
