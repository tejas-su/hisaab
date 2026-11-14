import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import 'entities/cycle_inputs.dart';
import 'entities/cycle_state.dart';
import 'entities/cycle_summary.dart';
import 'entities/occurrence.dart';
import 'entities/put_in_preview.dart';
import 'entities/range_forecast.dart';
import 'entities/spend_preview.dart';
import 'entities/week_day.dart';
import 'entities/yesterday_saving.dart';

/// The pure maths behind the hero: today's share, the state and the forecast (SPEC BR-3 to BR-7).
///
/// Shares are floored to whole rupees, so every amount the user sees is whole; forecasts are
/// rounded to the nearest ₹100 because they are estimates (DECISIONS D19).
abstract final class SafeToSpend {
  static const int _minimumHistoryDays = 3;
  static const int _forecastRoundingMajor = 100;

  /// Computes today's summary from [inputs]; [earliestEntryDate] is passed through for the Add tray.
  ///
  /// [spentThisWeek] and [week] are passed through for the *This week* view (FR-HO-2, BR-6a).
  /// [yesterday] holds the inputs as they stood yesterday, when yesterday is in the same cycle; it
  /// drives the "you saved ₹X yesterday" note (BR-8). [endsAtMonthEnd] is passed through for the
  /// hero's month-end wording (D116).
  static CycleSummary compute(
    CycleInputs inputs, {
    required CalendarDate earliestEntryDate,
    Money spentThisWeek = Money.zero,
    Option<CycleInputs> yesterday = const Option<CycleInputs>.none(),
    List<WeekDay> week = const <WeekDay>[],
    bool endsAtMonthEnd = false,
    List<Occurrence> waitingBills = const <Occurrence>[],
  }) {
    final int daysLeft = inputs.cycle.daysLeftFrom(inputs.today);
    final Money pool = _pool(inputs);
    final Money share = _share(pool, daysLeft);
    final Money remaining = pool - inputs.spentToday - inputs.savedExtraToday;
    final RangeForecast forecast = SafeToSpend.forecast(
      (cycle: inputs.cycle, today: inputs.today, remaining: remaining, paceSpentBefore: inputs.paceSpentBefore),
    );
    return CycleSummary(
      cycle: inputs.cycle,
      today: inputs.today,
      pool: pool,
      todayShare: share,
      spentToday: inputs.spentToday,
      tomorrowShare: _laterShare(remaining, daysLeft),
      state: _state(inputs, share: share, remaining: remaining, forecast: forecast),
      forecast: forecast,
      earliestEntryDate: earliestEntryDate,
      spentThisWeek: spentThisWeek,
      savedYesterday: yesterday.flatMap((CycleInputs before) => _savedYesterday(before, daysLeft)),
      week: week,
      endsAtMonthEnd: endsAtMonthEnd,
      savedExtraToday: inputs.savedExtraToday,
      waitingBills: waitingBills,
      income: inputs.income,
      billsDue: inputs.billsDue,
      savingsDue: inputs.savingsDue,
      fixedToday: inputs.fixedToday,
    );
  }

  /// `A` for the day [inputs] describe: its pool split over the days left from it (BR-4).
  static Money shareOn(CycleInputs inputs) => _share(_pool(inputs), inputs.cycle.daysLeftFrom(inputs.today));

  /// `A` for a [pool] split over [daysLeft] days, floored to whole rupees and never below zero (BR-4).
  /// *Fix my number* uses it to say what today's share would be after a fix (BR-18).
  static Money shareOfPool(Money pool, int daysLeft) => _share(pool, daysLeft);

  /// Previews spending [amount] more today against [summary], for the Add keypad (FR-AD-3).
  static SpendPreview previewSpend(CycleSummary summary, Money amount) {
    final Money spentAfter = summary.spentToday + amount;
    final Money left = summary.todayShare - spentAfter;
    if (!left.isNegative) {
      return FitsToday(left);
    }
    return OverTodayShare(
      over: Money.zero - left,
      tomorrow: _laterShare(summary.remaining - amount, summary.daysLeft),
    );
  }

  /// Previews putting [amount] into savings today against [summary] (D120): each later day
  /// gets the difference in tomorrow's share, or [PaydayTomorrow] on the cycle's last day.
  static PutInPreview previewPutIn(CycleSummary summary, Money amount) {
    final int daysLeft = summary.daysLeft;
    if (daysLeft <= 1) {
      return const PaydayTomorrow();
    }
    final Money before = _floorShare(summary.remaining, daysLeft - 1);
    final Money after = _floorShare(summary.remaining - amount, daysLeft - 1);
    return EachDayLess(before - after);
  }

  static Money _pool(CycleInputs inputs) =>
      inputs.income - inputs.keepAside - inputs.billsDue - inputs.spentBefore - inputs.billsPostedToday - inputs.fixedToday;

  static Money _share(Money pool, int daysLeft) => _atLeastZero(_floorShare(pool, daysLeft));

  // why: with nothing else changed, today's share is yesterday's plus `saved / D`, so the note
  // credits only the underspend, not income or bills that also moved overnight.
  static Option<YesterdaySaving> _savedYesterday(CycleInputs yesterday, int daysLeftToday) {
    final Money share = _share(_pool(yesterday), yesterday.cycle.daysLeftFrom(yesterday.today));
    // why: money put in extra yesterday went into savings, not to the days left (D120).
    final Money saved = share - yesterday.spentToday - yesterday.savedExtraToday;
    if (saved.isNegative || saved.isZero) {
      return const Option<YesterdaySaving>.none();
    }
    return Option<YesterdaySaving>.of(YesterdaySaving(saved: saved, eachDayMore: _floorShare(saved, daysLeftToday)));
  }

  static CycleState _state(
    CycleInputs inputs, {
    required Money share,
    required Money remaining,
    required RangeForecast forecast,
  }) {
    if (inputs.income.isZero && !inputs.hasIncomeRule) {
      return const NoIncome();
    }
    if (remaining.isNegative) {
      return OverCycle(Money.zero - remaining);
    }
    if (inputs.spentToday > share) {
      return OverToday(inputs.spentToday - share);
    }
    final bool underAQuarterLeft = (share - inputs.spentToday).amountMinor * 4 < share.amountMinor;
    if (share.isZero || underAQuarterLeft || _runsOutBy(forecast, inputs.cycle.end)) {
      return const SlowDown();
    }
    return const OnTrack();
  }

  static bool _runsOutBy(RangeForecast forecast, CalendarDate end) =>
      forecast is RunsOut && !forecast.date.isAfter(end);

  /// The range forecast (BR-7): too early, about how much is spare at the cycle's end, or the
  /// day the money runs out. Spends' pace chart uses it too, so the two never disagree (D133).
  // why: BR-7 pace uses only typed spending (V_prev / E); bills arrive on schedule, not at a pace.
  static RangeForecast forecast(ForecastInputs inputs) {
    final Money remaining = inputs.remaining;
    final int daysLeft = inputs.cycle.daysLeftFrom(inputs.today);
    final int elapsed = inputs.cycle.daysElapsedBefore(inputs.today);
    if (elapsed < _minimumHistoryDays) {
      return const TooEarlyToForecast();
    }
    final int paceTotal = inputs.paceSpentBefore.amountMinor;
    final int spareTimesElapsed = remaining.amountMinor * elapsed - paceTotal * (daysLeft - 1);
    if (spareTimesElapsed >= 0) {
      return LastsTillPayday(_roundToHundred(spareTimesElapsed / elapsed, remaining));
    }
    if (paceTotal == 0) {
      return RunsOut(inputs.today);
    }
    return RunsOut(inputs.today.addDays(_floorDiv(remaining.amountMinor * elapsed, paceTotal) + 1));
  }

  static Option<Money> _laterShare(Money remaining, int daysLeft) =>
      daysLeft > 1 ? Option<Money>.of(_floorShare(remaining, daysLeft - 1)) : const Option<Money>.none();

  static Money _floorShare(Money amount, int days) {
    final int minorPerMajor = amount.currency.minorPerMajor;
    return Money(_floorDiv(amount.amountMinor, days * minorPerMajor) * minorPerMajor, currency: amount.currency);
  }

  static Money _roundToHundred(double minor, Money like) {
    final int unit = _forecastRoundingMajor * like.currency.minorPerMajor;
    return Money((minor / unit).round() * unit, currency: like.currency);
  }

  static Money _atLeastZero(Money money) => money.isNegative ? Money(0, currency: money.currency) : money;

  // why: `~/` truncates towards zero; shares of a negative pool must round down (BR-4 floor).
  static int _floorDiv(int dividend, int divisor) {
    final int quotient = dividend ~/ divisor;
    final bool inexact = dividend % divisor != 0;
    return inexact && (dividend < 0) != (divisor < 0) ? quotient - 1 : quotient;
  }
}
