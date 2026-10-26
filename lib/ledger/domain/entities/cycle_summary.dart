import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import 'cycle_state.dart';
import 'range_forecast.dart';

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

  /// `D`: days left including today (BR-2).
  int get daysLeft => cycle.daysLeftFrom(today);

  /// The next payday, shown on the payday flag.
  CalendarDate get payday => cycle.end.addDays(1);

  /// `A − S_today`; negative when today is overspent. The hero never shows it below ₹0.
  Money get safeToday => todayShare - spentToday;

  @override
  List<Object?> get props =>
      <Object?>[cycle, today, pool, todayShare, spentToday, tomorrowShare, state, forecast, earliestEntryDate];
}
