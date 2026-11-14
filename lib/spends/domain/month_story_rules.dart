import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/pay_cycle.dart';
import '../../ledger/ledger.dart';
import 'category_shares.dart';
import 'entities/category_spend.dart';
import 'entities/month_story.dart';

/// What BR-20 reads for one cycle: its entries, the cycle before and whether that one was fully
/// tracked (BR-14 #1's rule).
final class StoryWindow extends Equatable {
  const StoryWindow({
    required this.cycle,
    required this.previous,
    required this.entries,
    required this.previousEntries,
    required this.previousTracked,
    required this.categories,
  });

  final PayCycle cycle;
  final PayCycle previous;

  /// Every entry dated in [cycle], of any kind.
  final List<Entry> entries;

  /// Every entry dated in [previous], of any kind.
  final List<Entry> previousEntries;
  final bool previousTracked;
  final List<Category> categories;

  @override
  List<Object?> get props => <Object?>[cycle, previous, entries, previousEntries, previousTracked, categories];
}

/// Which cycles get a month story, and what it says (SPEC BR-20, FR-SP-7).
abstract final class MonthStoryRules {
  /// Weekly cycles are too frequent for a once-a-month look back.
  static const int minCycleDays = 28;
  static const int minEntries = 10;

  /// Page 4 needs at least this many days with *Everyday* spending.
  static const int minSpendingDays = 7;

  /// The slim row shows on days 1 to 7 of the next cycle (FR-SP-7 AC-2).
  static const int rowDays = 7;

  /// A weekday is named when it holds at least this share of *Everyday* spending.
  static const int weekdayPercent = 35;
  static const int maxMoves = 3;

  /// Whether [cycle] gets a story: it ended before [today], lasts at least [minCycleDays] days and
  /// holds at least [minEntries] entries.
  static bool hasStory(PayCycle cycle, {required CalendarDate today, required int entryCount}) =>
      today.isAfter(cycle.end) && cycle.lengthInDays >= minCycleDays && entryCount >= minEntries;

  /// Whether [today] is in the first [rowDays] days of [current], when the slim row may show.
  static bool showsRow(PayCycle current, {required CalendarDate today}) => current.daysElapsedBefore(today) < rowDays;

  /// The story of [window]'s cycle; call it only for a cycle [hasStory] accepts.
  static MonthStory of(StoryWindow window) {
    final List<Entry> spent = _spending(window.entries);
    final Money income = _sum(window.entries.where((Entry e) => e.kind == EntryKind.got));
    final Money saved = _sum(window.entries.where((Entry e) => e.kind == EntryKind.saved));
    final Money bills = _sum(spent.where(_isBill));
    final List<Entry> everyday = spent.where((Entry e) => !_isBill(e)).toList();
    return MonthStory(
      cycle: window.cycle,
      previous: window.previous,
      entryCount: window.entries.length,
      income: income,
      saved: saved,
      bills: bills,
      everyday: _sum(everyday),
      notLogged: _sum(window.entries.where((Entry e) => e.kind == EntryKind.spent && e.isNotLogged)),
      rows: CategoryShares.of(window.entries, window.categories),
      days: _Days.of(window.cycle, everyday, room: income - saved - bills),
      comparison: _comparison(window),
    );
  }

  /// *Spent* entries that count as spending: every one but a *Not logged* fix.
  static List<Entry> _spending(Iterable<Entry> entries) =>
      entries.where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged).toList();

  static bool _isBill(Entry entry) => entry.recurringId != null;

  static Money _sum(Iterable<Entry> entries) => entries.fold(Money.zero, (Money total, Entry e) => total + e.amount);

  static Option<StoryComparison> _comparison(StoryWindow window) {
    final Money previousSpent = _sum(_spending(window.previousEntries));
    if (!window.previousTracked || previousSpent.isZero) {
      return const Option<StoryComparison>.none();
    }
    return Option<StoryComparison>.of(StoryComparison(
      previousSpent: previousSpent,
      change: _sum(_spending(window.entries)) - previousSpent,
      moves: _moves(CategoryShares.of(window.entries, window.categories), CategoryShares.of(window.previousEntries, window.categories)),
    ));
  }

  static List<CategoryMove> _moves(List<CategorySpend> now, List<CategorySpend> before) {
    final Map<int, CategorySpend> nowById = <int, CategorySpend>{for (final CategorySpend row in now) row.category.id: row};
    final Map<int, CategorySpend> beforeById = <int, CategorySpend>{for (final CategorySpend row in before) row.category.id: row};
    final List<CategoryMove> moves = <Category>{...now.map((CategorySpend r) => r.category), ...before.map((CategorySpend r) => r.category)}
        .map((Category c) => CategoryMove(category: c, change: _spentIn(nowById[c.id]) - _spentIn(beforeById[c.id])))
        .where((CategoryMove m) => !m.change.isZero)
        .toList()
      ..sort((CategoryMove a, CategoryMove b) => _byMove(a, b, nowById));
    return moves.take(maxMoves).toList();
  }

  static Money _spentIn(CategorySpend? row) => row?.spent ?? Money.zero;

  // why: the biggest change first; on a tie the bigger amount this cycle, then the grid's order (BR-20).
  static int _byMove(CategoryMove a, CategoryMove b, Map<int, CategorySpend> now) {
    final int bySize = b.change.amountMinor.abs().compareTo(a.change.amountMinor.abs());
    if (bySize != 0) {
      return bySize;
    }
    final int byAmount = _spentIn(now[b.category.id]).compareTo(_spentIn(now[a.category.id]));
    return byAmount != 0 ? byAmount : a.category.sort.compareTo(b.category.sort);
  }
}

/// Page 4's numbers, from a cycle's *Everyday* entries.
abstract final class _Days {
  static Option<StoryDays> of(PayCycle cycle, List<Entry> everyday, {required Money room}) {
    final List<Money> perDay = List<Money>.generate(
      cycle.lengthInDays,
      (int day) => MonthStoryRules._sum(everyday.where((Entry e) => cycle.start.daysUntil(e.date) == day)),
    );
    if (perDay.where((Money m) => !m.isZero).length < MonthStoryRules.minSpendingDays) {
      return const Option<StoryDays>.none();
    }
    final int peakIndex = _peakIndex(perDay);
    final Entry biggest = _biggestOn(everyday, cycle.start.addDays(peakIndex));
    return Option<StoryDays>.of(StoryDays(
      perDay: perDay,
      share: _share(room, cycle.lengthInDays),
      peakIndex: peakIndex,
      peakNote: Option<String>.fromNullable(biggest.note?.trim()).filter((String note) => note.isNotEmpty),
      peakCategoryId: biggest.categoryId,
      quietDays: perDay.where((Money m) => m.isZero).length,
      weekday: _weekday(cycle, perDay),
    ));
  }

  static Option<Money> _share(Money room, int days) {
    final int rupees = room.floorMajor ~/ days;
    return rupees > 0 ? Option<Money>.of(Money.fromMajor(rupees)) : const Option<Money>.none();
  }

  // why: the earliest day wins a tie, so only a strictly bigger day replaces it.
  static int _peakIndex(List<Money> perDay) =>
      perDay.indexed.fold(0, (int best, (int, Money) day) => day.$2 > perDay[best] ? day.$1 : best);

  // why: the biggest entry names the day; on a tie the first one saved.
  static Entry _biggestOn(List<Entry> everyday, CalendarDate date) =>
      everyday.where((Entry e) => e.date == date).reduce((Entry best, Entry e) => e.amount > best.amount ? e : best);

  static Option<StoryWeekday> _weekday(PayCycle cycle, List<Money> perDay) {
    final Map<int, (int, Money)> byWeekday = perDay.indexed.fold(<int, (int, Money)>{}, (Map<int, (int, Money)> totals, (int, Money) day) {
      final int weekday = cycle.start.addDays(day.$1).weekday;
      final (int count, Money total) = totals[weekday] ?? (0, Money.zero);
      return <int, (int, Money)>{...totals, weekday: (count + 1, total + day.$2)};
    });
    final MapEntry<int, (int, Money)> top =
        byWeekday.entries.reduce((MapEntry<int, (int, Money)> best, MapEntry<int, (int, Money)> e) => e.value.$2 > best.value.$2 ? e : best);
    final Money all = perDay.fold(Money.zero, (Money total, Money m) => total + m);
    return top.value.$2.amountMinor * 100 >= all.amountMinor * MonthStoryRules.weekdayPercent
        ? Option<StoryWeekday>.of(StoryWeekday(weekday: top.key, count: top.value.$1, total: top.value.$2))
        : const Option<StoryWeekday>.none();
  }
}
