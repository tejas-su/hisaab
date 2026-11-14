import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import '../../ledger/ledger.dart';
import 'entities/category_detail.dart';
import 'entities/cycle_bar.dart';
import 'entities/money_split.dart';
import 'entities/spends_comparison.dart';
import 'insight_rules.dart';

/// A cycle in the strip's window and how far back it is.
typedef StripCycle = ({PayCycle cycle, int cyclesBack});

/// The pure BR-21 rules behind the Spends graphs: the split, the comparison, each category's
/// detail and the months strip.
abstract final class SpendsBreakdown {
  /// The strip's window: the cycle shown and up to 5 before it.
  static const int stripCycles = 6;
  static const int _minFinished = 2;
  static const int _topEntries = 3;

  /// How [entries] split (BR-20's symbols): every kind is read, *Used* and card bills paid touch nothing.
  static MoneySplit split(Iterable<Entry> entries) => MoneySplit(
        income: _sum(entries.where((Entry e) => e.kind == EntryKind.got)),
        bills: _sum(_spending(entries).where((Entry e) => e.recurringId != null)),
        saved: _sum(entries.where((Entry e) => e.kind == EntryKind.saved)),
        everyday: _sum(_spending(entries).where((Entry e) => e.recurringId == null)),
        notLogged: _sum(entries.where((Entry e) => e.kind == EntryKind.spent && e.isNotLogged)),
      );

  /// [now] against [previous], cut at the same day while [now] runs; [None] when both are ₹0.
  static Option<SpendsComparison> comparison(InsightWindow now, InsightWindow previous) {
    final Money spentNow = _sum(_spending(now.entries).where((Entry e) => !e.date.isAfter(now.asOf)));
    final Money spentBefore = _sum(_spending(previous.entries).where((Entry e) => !e.date.isAfter(_sameDay(now, previous))));
    if (spentNow.isZero && spentBefore.isZero) {
      return const Option<SpendsComparison>.none();
    }
    return Option<SpendsComparison>.of(SpendsComparison(change: spentNow - spentBefore, wholeCycle: _isWhole(now)));
  }

  /// Each spent-in category of [now]: its change against [previous] by the same day, its biggest
  /// entries and its count.
  static Map<int, CategoryDetail> details(InsightWindow now, {required Option<InsightWindow> previous}) {
    final Map<int, List<Entry>> byCategory = _byCategory(_spending(now.entries).where((Entry e) => !e.date.isAfter(now.asOf)));
    final Option<Map<int, List<Entry>>> before = previous.map(
      (InsightWindow p) => _byCategory(_spending(p.entries).where((Entry e) => !e.date.isAfter(_sameDay(now, p)))),
    );
    return byCategory.map((int id, List<Entry> entries) => MapEntry<int, CategoryDetail>(
          id,
          CategoryDetail(
            change: before.map((Map<int, List<Entry>> b) => _sum(entries) - _sum(b[id] ?? const <Entry>[])),
            top: (<Entry>[...entries]..sort(_biggestFirst)).take(_topEntries).toList(),
            count: entries.length,
          ),
        ));
  }

  /// The months strip over [window] (newest first), oldest first, from the first cycle that ended
  /// on or after [firstLogged]; [None] with fewer than 2 finished cycles or no money in for the
  /// cycle shown (the first of [window]).
  static Option<MonthsStrip> strip(List<StripCycle> window, {required List<Entry> entries, required CalendarDate today, required Option<CalendarDate> firstLogged}) {
    final List<CycleBar> bars = firstLogged
        .map((CalendarDate first) => window.where((StripCycle c) => !c.cycle.end.isBefore(first)).take(stripCycles))
        .getOrElse(() => const <StripCycle>[])
        .map((StripCycle c) => _bar(c, entries, today))
        .toList()
        .reversed
        .toList();
    final bool enough = bars.where((CycleBar b) => !b.isRunning).length >= _minFinished;
    return enough && bars.last.hasIncome ? Option<MonthsStrip>.of(MonthsStrip(bars)) : const Option<MonthsStrip>.none();
  }

  static CycleBar _bar(StripCycle c, List<Entry> entries, CalendarDate today) {
    final bool running = c.cycle.contains(today);
    return CycleBar(
      cycle: c.cycle,
      cyclesBack: c.cyclesBack,
      split: split(entries.where((Entry e) => c.cycle.contains(e.date) && !e.date.isAfter(today))),
      isRunning: running,
      daysLeft: running ? today.daysUntil(c.cycle.end) : 0,
    );
  }

  static bool _isWhole(InsightWindow window) => window.asOf == window.cycle.end;

  // why: day-of-cycle k meets day min(k, previous length) so 28-, 30- and 31-day cycles line up, as
  // in BR-14 #1; a finished cycle meets the whole cycle before.
  static CalendarDate _sameDay(InsightWindow now, InsightWindow previous) {
    if (_isWhole(now)) {
      return previous.cycle.end;
    }
    final int day = now.cycle.start.daysUntil(now.asOf);
    return previous.cycle.start.addDays(day < previous.cycle.lengthInDays ? day : previous.cycle.lengthInDays - 1);
  }

  static Iterable<Entry> _spending(Iterable<Entry> entries) => entries.where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged);

  static Map<int, List<Entry>> _byCategory(Iterable<Entry> entries) => entries.fold(
        <int, List<Entry>>{},
        (Map<int, List<Entry>> groups, Entry e) => <int, List<Entry>>{...groups, e.categoryId: <Entry>[...?groups[e.categoryId], e]},
      );

  // why: the biggest first; a tie goes to the earlier day, then to the entry saved first (BR-21).
  static int _biggestFirst(Entry a, Entry b) {
    final int byAmount = b.amount.compareTo(a.amount);
    if (byAmount != 0) {
      return byAmount;
    }
    final int byDay = a.date.compareTo(b.date);
    return byDay != 0 ? byDay : a.id.compareTo(b.id);
  }

  static Money _sum(Iterable<Entry> entries) => entries.fold(Money.zero, (Money total, Entry e) => total + e.amount);
}
