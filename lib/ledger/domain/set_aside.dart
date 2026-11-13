import '../../core/money/money.dart';
import 'entities/recurring_rule.dart';
import 'entities/saving_totals.dart';
import 'entities/set_aside_summary.dart';

/// The maths of what is still set aside in a saving (SPEC BR-19). It is computed, never stored (D120).
abstract final class SetAside {
  /// What is left of a saving after its uses: [putIn] minus [used], never below ₹0, so a put-in
  /// deleted after a use can't make it negative (E99).
  static Money of(Money putIn, Money used) => used > putIn ? Money.zero : putIn - used;

  /// The set-aside of each of [activeSavings] from [totals], and their sum.
  ///
  /// A saving that was never put into or used has ₹0. *Put in extra* belongs to no saving and
  /// a deleted saving is not in [activeSavings], so neither is counted (E98, E100).
  static SetAsideSummary summarise(List<RecurringRule> activeSavings, SavingTotals totals) {
    final Map<int, Money> perSaving = <int, Money>{
      for (final RecurringRule saving in activeSavings)
        saving.id: of(
          totals.bySaving[saving.id]?.putIn ?? Money.zero,
          totals.bySaving[saving.id]?.used ?? Money.zero,
        ),
    };
    return SetAsideSummary(
      perSaving: perSaving,
      stillSetAside: perSaving.values.fold(Money.zero, (Money sum, Money each) => sum + each),
      anyUse: totals.anyUse,
    );
  }
}
