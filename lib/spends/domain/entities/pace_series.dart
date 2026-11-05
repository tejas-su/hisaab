import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../ledger/ledger.dart';

/// Whether spending so far is at or under the steady line, or over it (SPEC FR-SP-3).
enum PaceVerdict { belowPace, abovePace }

/// The pace chart's data: cumulative *Spent* per day against a steady line to [budget] (FR-SP-3).
final class PaceSeries extends Equatable {
  const PaceSeries({
    required this.cycleDays,
    required this.spentByDay,
    required this.billsByDay,
    required this.budget,
    required this.axisStep,
  });

  /// Builds the series for [cycle] up to [asOf] (today, or the cycle's end for a past cycle).
  ///
  /// [budget] is `I − K`. The steady line steps up by each bill on its day: the bills [entries]
  /// posted, and [billsDue], the bills still to come. Returns [None] when [budget] is ₹0 or less,
  /// since there is no steady line.
  static Option<PaceSeries> of(
    Iterable<Entry> entries, {
    required PayCycle cycle,
    required CalendarDate asOf,
    required Money budget,
    List<DatedAmount> billsDue = const <DatedAmount>[],
  }) {
    if (budget.isNegative || budget.isZero) {
      return const Option<PaceSeries>.none();
    }
    final Iterable<Entry> spent = entries.where((Entry e) => e.kind == EntryKind.spent && cycle.contains(e.date) && !e.date.isAfter(asOf));
    final List<Money> cumulative = _runningTotals(spent.map((Entry e) => (date: e.date, amount: e.amount)), cycle, asOf, budget);
    final List<DatedAmount> bills = <DatedAmount>[
      ...spent.where((Entry e) => e.recurringId != null).map((Entry e) => (date: e.date, amount: e.amount)),
      ...billsDue.where((DatedAmount due) => cycle.contains(due.date)),
    ];
    final List<Money> billsByDay = _runningTotals(bills, cycle, cycle.end, budget);
    final Money top = <Money>[cumulative.last, budget, billsByDay.last].reduce((Money a, Money b) => a > b ? a : b);
    return Option<PaceSeries>.of(
      PaceSeries(
        cycleDays: cycle.lengthInDays,
        spentByDay: cumulative,
        billsByDay: billsByDay,
        budget: budget,
        axisStep: _niceStep(budget, top),
      ),
    );
  }

  /// The running total of [amounts] at the end of each day from the cycle's start to [through].
  static List<Money> _runningTotals(Iterable<DatedAmount> amounts, PayCycle cycle, CalendarDate through, Money budget) {
    final Map<int, int> byDay = amounts.fold(<int, int>{}, (Map<int, int> days, DatedAmount a) {
      final int day = cycle.start.daysUntil(a.date);
      return <int, int>{...days, day: (days[day] ?? 0) + a.amount.amountMinor};
    });
    return List<int>.generate(cycle.start.daysUntil(through) + 1, (int day) => byDay[day] ?? 0)
        .fold(<int>[], (List<int> sums, int day) => <int>[...sums, (sums.isEmpty ? 0 : sums.last) + day])
        .map((int minor) => Money(minor, currency: budget.currency))
        .toList();
  }

  /// Days in the cycle; the steady line reaches [budget] at the last one.
  final int cycleDays;

  /// Running total of spending at the end of each day from the cycle's start to its as-of day.
  final List<Money> spentByDay;

  /// Running total of the cycle's bills at the end of each day, posted or still to come, for
  /// every day of the cycle.
  final List<Money> billsByDay;

  /// `I − K`: the money the cycle has to spend.
  final Money budget;

  /// Gap between y-axis labels: a third of [budget] rounded up to 1, 2 or 5 × 10ⁿ rupees, raised
  /// up the same ladder when needed so at most 4 steps sit above ₹0 (D115).
  final Money axisStep;

  /// Total spent up to the as-of day.
  Money get spentSoFar => spentByDay.last;

  /// The steady line's value at the end of day [dayIndex] (0 is the cycle's start): the bills
  /// due by then, plus an even share of the rest of [budget] for each day, floored to the rupee.
  // why: a straight ramp put rent on day 2 far above the line, so the verdict read "Spending
  // faster" for most of the month with nothing else spent (D129).
  Money steadyThrough(int dayIndex) {
    final int perMajor = budget.currency.minorPerMajor;
    final int everyday = budget.amountMinor - billsByDay.last.amountMinor;
    final int share = everyday <= 0 ? 0 : everyday * (dayIndex + 1) ~/ (cycleDays * perMajor) * perMajor;
    return billsByDay[dayIndex] + Money(share, currency: budget.currency);
  }

  /// Below pace when spending so far is at or under the steady line on the same day.
  PaceVerdict get verdict =>
      spentSoFar > steadyThrough(spentByDay.length - 1) ? PaceVerdict.abovePace : PaceVerdict.belowPace;

  /// The chart's top: the budget, or the spending or the bills if either went higher.
  Money get top => <Money>[spentSoFar, budget, billsByDay.last].reduce((Money a, Money b) => a > b ? a : b);

  /// Fixed y-axis labels: ₹0 and every [axisStep] up to [top].
  List<Money> get axisLabels => <Money>[
        for (int minor = 0; minor <= top.amountMinor; minor += axisStep.amountMinor) Money(minor, currency: budget.currency),
      ];

  // why: a step from the budget alone drew one label per step up to a big overspend (₹1 budget,
  // ₹1L spent gave 1,00,001 labels) and hung the app; the second floor keeps 5 labels at most.
  static Money _niceStep(Money budget, Money top) {
    final int perMajor = budget.currency.minorPerMajor;
    final int third = (budget.amountMinor + 3 * perMajor - 1) ~/ (3 * perMajor);
    final int fifthOfTop = top.amountMinor ~/ (5 * perMajor) + 1;
    final int floor = third > fifthOfTop ? third : fifthOfTop;
    int magnitude = 1;
    while (magnitude * 10 <= floor) {
      magnitude *= 10;
    }
    final int step = <int>[1, 2, 5, 10].map((int m) => m * magnitude).firstWhere((int s) => s >= floor);
    return Money(step * perMajor, currency: budget.currency);
  }

  @override
  List<Object?> get props => <Object?>[cycleDays, spentByDay, billsByDay, budget, axisStep];
}
