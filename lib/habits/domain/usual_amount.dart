import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import 'habit_rules.dart';

/// Picks the one amount a habit is usually logged with (SPEC BR-17 rule 4).
abstract final class UsualAmount {
  /// The exact amount that makes up at least 70% of the weight of [hits], the entries inside a
  /// habit's window with their recency weights.
  ///
  /// Returns [Some] with that amount, exactly as it was logged, or [None] when no single amount
  /// reaches 70% or [hits] is empty.
  static Option<Money> pick(List<({Money amount, double weight})> hits) {
    final Map<Money, double> weightByAmount = hits.fold(
      <Money, double>{},
      (Map<Money, double> sums, ({Money amount, double weight}) hit) => <Money, double>{
        ...sums,
        hit.amount: (sums[hit.amount] ?? 0) + hit.weight,
      },
    );
    final double total = weightByAmount.values.fold(0, (double sum, double weight) => sum + weight);
    return Option<Money>.fromNullable(
      weightByAmount.entries
          // why: cross-multiplied, so the 70% bar is never a rounded division.
          .where(
            (MapEntry<Money, double> entry) =>
                HabitRules.amountShareDen * entry.value >= HabitRules.amountShareNum * total,
          )
          .map((MapEntry<Money, double> entry) => entry.key)
          .firstOrNull,
    );
  }
}
