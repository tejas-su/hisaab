import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import 'cycle_state.dart';
import 'occurrence.dart';
import 'range_forecast.dart';
import 'week_day.dart';
import 'yesterday_saving.dart';

/// Today's answer to "how much can I safely spend?" for one cycle (SPEC BR-2 to BR-7).
final class CycleSummary extends Equatable {
  const CycleSummary({
    required this.cycle,
    required this.today,
    required this.pool,
    required this.todayShare,
    required this.spentToday,
    required this.tomorrowShare,
    required this.state,
    required this.forecast,
    required this.earliestEntryDate,
    this.spentThisWeek = Money.zero,
    this.savedYesterday = const Option<YesterdaySaving>.none(),
    this.week = const <WeekDay>[],
    this.endsAtMonthEnd = false,
    this.savedExtraToday = Money.zero,
    this.waitingBills = const <Occurrence>[],
  });

  final PayCycle cycle;
  final CalendarDate today;

  /// `P`: money left for the rest of the cycle at the start of today (BR-3).
  final Money pool;

  /// `A`: today's share, fixed for the whole day (BR-4).
  final Money todayShare;

  /// `S_today`.
  final Money spentToday;

  /// Each later day's share after today's spending; [None] on the cycle's last day (BR-4).
  final Option<Money> tomorrowShare;
  final CycleState state;
  final RangeForecast forecast;

  /// The oldest date an entry may be given: the start of the previous cycle (BR-10).
  final CalendarDate earliestEntryDate;

  /// *Spent* entries from Monday (or the cycle start, if later) to today (FR-HO-2).
  final Money spentThisWeek;

  /// What yesterday's underspend added to each day; [None] when nothing was saved or
  /// yesterday was in the previous cycle (BR-8).
  final Option<YesterdaySaving> savedYesterday;

  /// Monday (or the cycle start, if later) to today, oldest first, each as it stood (BR-6a).
  final List<WeekDay> week;

  /// True when the cycle follows the calendar month ("It changes", or month start on the 1st), so it
  /// ends at month end and has no payday to count down to (BR-1; DECISIONS D116).
  final bool endsAtMonthEnd;

  /// Money put in extra today; it thins the days after today, never today's share (D120).
  final Money savedExtraToday;

  /// Changing and card bills waiting for the user to say how much, oldest first (D123).
  final List<Occurrence> waitingBills;

  /// What is left for the rest of the cycle after today's spending and today's extras (BR-4).
  Money get remaining => pool - spentToday - savedExtraToday;

  /// `D`: days left including today (BR-2).
  int get daysLeft => cycle.daysLeftFrom(today);

  /// The next payday, shown on the payday flag.
  CalendarDate get payday => cycle.end.addDays(1);

  /// `A − S_today`; negative when today is overspent. The hero never shows it below ₹0.
  Money get safeToday => todayShare - spentToday;

  /// `A × min(7, D) − spent this week`; negative when the week is overspent (FR-HO-2).
  Money get safeThisWeek => todayShare * (daysLeft < _daysInWeek ? daysLeft : _daysInWeek) - spentThisWeek;

  static const int _daysInWeek = 7;

  @override
  List<Object?> get props =>
      <Object?>[cycle, today, pool, todayShare, spentToday, tomorrowShare, state, forecast, earliestEntryDate, spentThisWeek, savedYesterday, week, endsAtMonthEnd, savedExtraToday, waitingBills];
}
