import '../../core/money/money.dart';
import '../../ledger/ledger.dart';
import 'entities/category_spend.dart';

/// Totals *Spent* entries per category and shares them out in whole percentages (SPEC BR-13).
abstract final class CategoryShares {
  static const int _whole = 100;

  /// One row per category in [categories] that has *Spent* [entries], biggest first (ties in
  /// the grid's order). Percentages use the largest-remainder method, so they sum to exactly 100.
  static List<CategorySpend> of(Iterable<Entry> entries, List<Category> categories) {
    final Map<int, Money> spent = _spentByCategory(entries);
    final List<(Category, Money)> rows = categories
        .where((Category c) => spent.containsKey(c.id))
        .map((Category c) => (c, spent[c.id] ?? Money.zero))
        .toList()
      ..sort(_biggestFirst);
    final int total = rows.fold(0, (int sum, (Category, Money) row) => sum + row.$2.amountMinor);
    final List<int> percents = _largestRemainder(rows.map(((Category, Money) row) => row.$2.amountMinor).toList(), total);
    return <CategorySpend>[
      for (final (int i, (Category category, Money amount)) in rows.indexed)
        CategorySpend(category: category, spent: amount, percent: percents[i]),
    ];
  }

  static Map<int, Money> _spentByCategory(Iterable<Entry> entries) => entries
      .where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged)
      .fold(<int, Money>{}, (Map<int, Money> totals, Entry e) => <int, Money>{
            ...totals,
            e.categoryId: (totals[e.categoryId] ?? Money(0, currency: e.amount.currency)) + e.amount,
          });

  static int _biggestFirst((Category, Money) a, (Category, Money) b) {
    final int byAmount = b.$2.compareTo(a.$2);
    return byAmount != 0 ? byAmount : a.$1.sort.compareTo(b.$1.sort);
  }

  // why: rows arrive biggest first, so on equal remainders the bigger amount gets the extra point.
  static List<int> _largestRemainder(List<int> amounts, int total) {
    final List<int> floors = amounts.map((int a) => a * _whole ~/ total).toList();
    final int missing = _whole - floors.fold(0, (int sum, int f) => sum + f);
    final List<int> byRemainder = List<int>.generate(amounts.length, (int i) => i)
      ..sort((int a, int b) => (amounts[b] * _whole % total).compareTo(amounts[a] * _whole % total));
    final Set<int> bumped = byRemainder.take(missing).toSet();
    return <int>[for (final (int i, int f) in floors.indexed) bumped.contains(i) ? f + 1 : f];
  }
}
