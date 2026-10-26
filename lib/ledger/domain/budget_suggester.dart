import '../../core/money/money.dart';
import 'entities/entry.dart';
import 'entities/entry_kind.dart';

/// Suggests a limit per category from what was spent in a cycle (SPEC BR-12).
abstract final class BudgetSuggester {
  static const int _roundingMajor = 500;

  /// Maps each category with *Spent* entries in [entries] to its total, rounded up to the next
  /// ₹500. Categories with nothing spent get no limit.
  static Map<int, Money> suggest(Iterable<Entry> entries) => entries
      .where((Entry e) => e.kind == EntryKind.spent)
      .fold(<int, Money>{}, (Map<int, Money> totals, Entry e) => <int, Money>{
            ...totals,
            e.categoryId: (totals[e.categoryId] ?? Money(0, currency: e.amount.currency)) + e.amount,
          })
      .map((int categoryId, Money total) => MapEntry<int, Money>(categoryId, _roundUp(total)));

  static Money _roundUp(Money total) {
    final int unit = _roundingMajor * total.currency.minorPerMajor;
    return Money((total.amountMinor + unit - 1) ~/ unit * unit, currency: total.currency);
  }
}
