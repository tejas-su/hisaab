import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import '../../ledger/ledger.dart';
import 'entities/insight.dart';

/// A cycle's entries as seen on [asOf]: today for the current cycle, the last day for a past one.
final class InsightWindow extends Equatable {
  const InsightWindow({required this.cycle, required this.asOf, required this.entries});

  final PayCycle cycle;
  final CalendarDate asOf;
  final List<Entry> entries;

  @override
  List<Object?> get props => <Object?>[cycle, asOf, entries];
}

/// The pure BR-14 rules #1 to #3; each gives at most one insight (DECISIONS D50).
abstract final class InsightRules {
  static final Money _minimumRise = Money.fromMajor(1000);
  static const int _minimumSteadyEntries = 4;
  static const int _minimumSteadyWeeks = 2;
  static const int _daysInWeek = 7;

  /// Evaluates [current] in priority order. [previous] is the cycle before, when the app was in
  /// use for all of it; without it there is no "up from last month".
  static List<Insight> evaluate(InsightWindow current, {required Option<InsightWindow> previous}) => <Option<Insight>>[
        previous.flatMap((InsightWindow before) => _categoryUp(current, before)),
        _biggestSpend(current),
        _steadiest(current),
      ].expand((Option<Insight> insight) => insight.match(() => const <Insight>[], (Insight i) => <Insight>[i])).toList();

  // why: day-of-cycle k is compared with day min(k, previous length) so 28-, 30- and 31-day
  // cycles line up (BR-14 #1).
  static Option<Insight> _categoryUp(InsightWindow current, InsightWindow previous) {
    final int day = current.cycle.start.daysUntil(current.asOf);
    final int previousDay = day < previous.cycle.lengthInDays ? day : previous.cycle.lengthInDays - 1;
    final Map<int, int> now = _spentThrough(current.entries, current.asOf);
    final Map<int, int> before = _spentThrough(previous.entries, previous.cycle.start.addDays(previousDay));
    final List<CategoryUp> ups = now.entries
        .map((MapEntry<int, int> e) => (e.key, e.value, before[e.key] ?? 0))
        .where(((int, int, int) c) => c.$2 - c.$3 >= _minimumRise.amountMinor && c.$2 * 5 >= c.$3 * 6)
        .map(((int, int, int) c) => CategoryUp(categoryId: c.$1, rise: Money(c.$2 - c.$3)))
        .toList();
    return Option<Insight>.fromNullable(
      ups.fold<CategoryUp?>(null, (CategoryUp? best, CategoryUp up) => best == null || up.rise > best.rise ? up : best),
    );
  }

  static Option<Insight> _biggestSpend(InsightWindow window) {
    final Map<int, List<Entry>> byCategory = _typedSpending(window.entries, window.asOf);
    final List<Entry> standouts = byCategory.values.expand((List<Entry> entries) {
      final int twiceMedian = _twiceMedian(entries.map((Entry e) => e.amount.amountMinor).toList()..sort());
      return entries.where((Entry e) => e.amount.amountMinor > twiceMedian);
    }).toList();
    return Option<Entry>.fromNullable(
      standouts.fold<Entry?>(null, (Entry? best, Entry e) => best == null || e.amount > best.amount ? e : best),
    ).map((Entry e) => BiggestSpend(categoryId: e.categoryId, amount: e.amount, date: e.date));
  }

  // why: steadiness compares spread relative to size (coefficient of variation), otherwise the
  // smallest category always "wins"; only whole weeks count (DECISIONS D50).
  static Option<Insight> _steadiest(InsightWindow window) {
    final bool finished = window.asOf == window.cycle.end;
    final int weeks = (window.cycle.start.daysUntil(window.asOf) + (finished ? 1 : 0)) ~/ _daysInWeek;
    if (weeks < _minimumSteadyWeeks) {
      return const Option<Insight>.none();
    }
    final CalendarDate lastCounted = window.cycle.start.addDays(weeks * _daysInWeek - 1);
    final List<(int, double, int)> candidates = _typedSpending(window.entries, lastCounted)
        .entries
        .where((MapEntry<int, List<Entry>> e) => e.value.length >= _minimumSteadyEntries)
        .map((MapEntry<int, List<Entry>> e) => _spread(e.key, e.value, window.cycle.start, weeks))
        .toList();
    return Option<(int, double, int)>.fromNullable(
      candidates.fold<(int, double, int)?>(
        null,
        ((int, double, int)? best, (int, double, int) c) =>
            best == null || c.$2 < best.$2 || (c.$2 == best.$2 && c.$3 > best.$3) ? c : best,
      ),
    ).map(((int, double, int) c) => SteadiestCategory(categoryId: c.$1));
  }

  /// (category, squared coefficient of variation of weekly totals, total). Entries are positive,
  /// so the mean is never 0.
  static (int, double, int) _spread(int categoryId, List<Entry> entries, CalendarDate start, int weeks) {
    final List<int> weekly = List<int>.generate(
      weeks,
      (int week) => entries
          .where((Entry e) => start.daysUntil(e.date) ~/ _daysInWeek == week)
          .fold(0, (int sum, Entry e) => sum + e.amount.amountMinor),
    );
    final int total = weekly.fold(0, (int sum, int w) => sum + w);
    final double mean = total / weeks;
    final double variance = weekly.fold(0.0, (double sum, int w) => sum + (w - mean) * (w - mean)) / weeks;
    return (categoryId, variance / (mean * mean), total);
  }

  static Map<int, int> _spentThrough(List<Entry> entries, CalendarDate last) => entries
      .where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged && !e.date.isAfter(last))
      .fold(<int, int>{}, (Map<int, int> sums, Entry e) => <int, int>{
            ...sums,
            e.categoryId: (sums[e.categoryId] ?? 0) + e.amount.amountMinor,
          });

  // why: bills posted by a rule are expected, so they never count as a standout or a habit.
  static Map<int, List<Entry>> _typedSpending(List<Entry> entries, CalendarDate last) => entries
      .where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged && e.recurringId == null && !e.date.isAfter(last))
      .fold(<int, List<Entry>>{}, (Map<int, List<Entry>> groups, Entry e) => <int, List<Entry>>{
            ...groups,
            e.categoryId: <Entry>[...?groups[e.categoryId], e],
          });

  /// Twice the median of [sorted], so an odd middle and an even pair's sum compare alike.
  static int _twiceMedian(List<int> sorted) {
    final int middle = sorted.length ~/ 2;
    return sorted.length.isOdd ? 2 * sorted[middle] : sorted[middle - 1] + sorted[middle];
  }
}
