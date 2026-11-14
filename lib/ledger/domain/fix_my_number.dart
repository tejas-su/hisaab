import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import 'entities/cycle_summary.dart';
import 'entities/entry_kind.dart';
import 'entities/fix_preview.dart';
import 'safe_to_spend.dart';

/// The maths of *Fix my number*: compares the figure the user typed with hisaab's own and says
/// what one *Not logged* entry would change (SPEC BR-18).
abstract final class FixMyNumber {
  static const int _closeMajor = 50;
  static const int _roundAnswerMajor = 100;
  static const int _guardDivisor = 10;

  /// `H`: what hisaab expects the user still holds of this cycle's money, **unclamped** so it may
  /// be zero or below (E78). It keeps the bills and savings still to come, which are still in the
  /// account.
  static Money held(CycleSummary summary) => summary.remaining + summary.billsDue + summary.savingsDue;

  /// The preview for [typedRupees] (none while nothing is typed) against [summary].
  ///
  /// Order of the states: equal, close, then lower (short before over today before lower) or
  /// higher (large before higher).
  static FixPreview preview(CycleSummary summary, Option<int> typedRupees) => typedRupees.match(
        () => FixEmpty(held: held(summary)),
        (int typed) => _compare(summary, typed),
      );

  /// The entry [typedRupees] would post, or none when the answer is equal or close.
  static Option<FixPost> post(CycleSummary summary, int typedRupees) {
    final FixPreview preview = _compare(summary, typedRupees);
    if (preview is! FixChange) {
      return const Option<FixPost>.none();
    }
    final EntryKind kind = _gapMinor(summary, typedRupees) > 0 ? EntryKind.spent : EntryKind.got;
    return Option<FixPost>.of(FixPost(kind: kind, amount: preview.gap));
  }

  /// The whole rupees a fix for [typedRupees] would post, signed: above zero is money missing (a
  /// *Spent* fix), below zero is a *Got* fix, zero is equal. The write compares it with what the user
  /// saw to refuse a stale one, so a drift under ₹1 never refuses a save (BR-18 *Stale write*, D191).
  static int signedRupees(CycleSummary summary, int typedRupees) =>
      _gapMinor(summary, typedRupees) ~/ summary.pool.currency.minorPerMajor;

  static int _gapMinor(CycleSummary summary, int typedRupees) =>
      held(summary).amountMinor - Money.fromMajor(typedRupees, currency: summary.pool.currency).amountMinor;

  static FixPreview _compare(CycleSummary summary, int typed) {
    final int gapMinor = _gapMinor(summary, typed);
    final Money gap = _wholeRupees(gapMinor.abs(), summary);
    if (gap.isZero) {
      return FixEqual(held: held(summary));
    }
    if (_isClose(typed, gapMinor.abs(), summary)) {
      return FixClose(held: held(summary));
    }
    return gapMinor > 0 ? _lower(summary, typed, gap) : _higher(summary, gap, gapMinor);
  }

  // why: a rounded answer ("17,400") is within ₹50 of the truth, and a ₹30 entry would be noise
  // (E73). T must be a multiple of ₹100 and the gap at most ₹50.00, so ₹50.01 is not close.
  static bool _isClose(int typed, int gapMinorAbs, CycleSummary summary) =>
      typed % _roundAnswerMajor == 0 &&
      gapMinorAbs <= Money.fromMajor(_closeMajor, currency: summary.pool.currency).amountMinor;

  static Money _wholeRupees(int minor, CycleSummary summary) {
    final int perMajor = summary.pool.currency.minorPerMajor;
    return Money(minor ~/ perMajor * perMajor, currency: summary.pool.currency);
  }

  static FixChange _lower(CycleSummary summary, int typed, Money gap) {
    final Money dueStill = summary.billsDue + summary.savingsDue;
    final Money typedMoney = Money.fromMajor(typed, currency: summary.pool.currency);
    final Money after = _shareAfter(summary, summary.pool - gap);
    final Money perDay = summary.todayShare - after;
    if (typedMoney < dueStill) {
      return FixShort(held: held(summary), gap: gap, shareAfter: after, perDay: perDay, short: dueStill - typedMoney);
    }
    if (after < summary.spentToday) {
      return FixOverToday(held: held(summary), gap: gap, shareAfter: after, perDay: perDay, over: summary.spentToday - after);
    }
    return FixLower(held: held(summary), gap: gap, shareAfter: after, perDay: perDay, lastDay: summary.daysLeft == 1);
  }

  static FixChange _higher(CycleSummary summary, Money gap, int gapMinor) {
    final Money after = _shareAfter(summary, summary.pool + gap);
    final Money perDay = after - summary.todayShare;
    // why: strictly above I ÷ 10 asks the question; a gap of exactly I ÷ 10 saves with *Fix it*
    // (BR-18 *Large*: `−gap > I ÷ 10`).
    if (-gapMinor > summary.income.amountMinor ~/ _guardDivisor) {
      return FixLarge(held: held(summary), gap: gap, shareAfter: after, perDay: perDay);
    }
    return FixHigher(held: held(summary), gap: gap, shareAfter: after, perDay: perDay, lastDay: summary.daysLeft == 1);
  }

  // why: the same floor-and-clamp as the hero, over a pool that may now be negative (BR-4).
  static Money _shareAfter(CycleSummary summary, Money pool) => SafeToSpend.shareOfPool(pool, summary.daysLeft);
}
