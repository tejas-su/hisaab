import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import 'entry_kind.dart';

/// Which first line the preview shows for hisaab's own figure `H` (BR-18, D181).
enum HeldLine {
  /// `H` is above ₹0: "hisaab thought ₹17,430."
  amount,

  /// `H` is exactly ₹0: "hisaab thought nothing was left."
  nothing,

  /// `H` is below ₹0 (the month was already overspent): "hisaab thought you were ₹300 short."
  short,
}

/// What *Fix my number* shows for one typed figure `T` against hisaab's figure `H` (BR-18).
///
/// Every state keeps [held], the unclamped `H`, so the first line can say what hisaab thought.
sealed class FixPreview extends Equatable {
  const FixPreview({required this.held});

  /// `H`: what hisaab expected the user still holds of this cycle's money; may be zero or below.
  final Money held;

  /// Which first line [held] gets (BR-18, D181).
  HeldLine get heldLine => held.isZero
      ? HeldLine.nothing
      : held.isNegative
          ? HeldLine.short
          : HeldLine.amount;

  @override
  List<Object?> get props => <Object?>[held];
}

/// Nothing is typed yet: the helper shows and `H` stays hidden (FR-FX-2 AC-2).
final class FixEmpty extends FixPreview {
  const FixEmpty({required super.held});
}

/// `T` equals `H` to within ₹1: nothing to fix (E72).
final class FixEqual extends FixPreview {
  const FixEqual({required super.held});
}

/// A round answer within ₹50 of `H`: close enough, nothing to fix (E73).
final class FixClose extends FixPreview {
  const FixClose({required super.held});
}

/// A fix that would post an entry: the whole-rupee [gap] and its effect on today's share.
sealed class FixChange extends FixPreview {
  const FixChange({required super.held, required this.gap, required this.shareAfter, required this.perDay});

  /// The rupees the entry would post (`n`), always whole and above zero.
  final Money gap;

  /// `A_after`: today's share as it would be after the entry is posted (BR-18).
  final Money shareAfter;

  /// `n_day`: how much each day's share changes; zero reads "Each day stays about the same."
  final Money perDay;

  @override
  List<Object?> get props => <Object?>[...super.props, gap, shareAfter, perDay];
}

/// Money is missing and nothing special follows: a *Spent* fix. [lastDay] swaps the per-day line.
final class FixLower extends FixChange {
  const FixLower({
    required super.held,
    required super.gap,
    required super.shareAfter,
    required super.perDay,
    required this.lastDay,
  });

  /// `D = 1`: "Today takes all of it." replaces the per-day line (F11).
  final bool lastDay;

  @override
  List<Object?> get props => <Object?>[...super.props, lastDay];
}

/// Lower, and the user holds less than the bills and savings still to come: [short] is the
/// shortfall `m`. It informs and never blocks (F4).
final class FixShort extends FixChange {
  const FixShort({
    required super.held,
    required super.gap,
    required super.shareAfter,
    required super.perDay,
    required this.short,
  });

  /// `m = (B + R) − T`.
  final Money short;

  @override
  List<Object?> get props => <Object?>[...super.props, short];
}

/// Lower, and the new share falls below what was already spent today (D190): [over] is `o`.
final class FixOverToday extends FixChange {
  const FixOverToday({
    required super.held,
    required super.gap,
    required super.shareAfter,
    required super.perDay,
    required this.over,
  });

  /// `o = S_today − A_after`.
  final Money over;

  @override
  List<Object?> get props => <Object?>[...super.props, over];
}

/// hisaab under-counted by a gap within `I ÷ 10`: a *Got* fix. [lastDay] swaps the per-day line.
final class FixHigher extends FixChange {
  const FixHigher({
    required super.held,
    required super.gap,
    required super.shareAfter,
    required super.perDay,
    required this.lastDay,
  });

  /// `D = 1`: "Today gets all of it." replaces the per-day line (F11).
  final bool lastDay;

  @override
  List<Object?> get props => <Object?>[...super.props, lastDay];
}

/// A higher gap above `I ÷ 10`: *Fix it* asks "Is all of it from this month?" first (D167).
final class FixLarge extends FixChange {
  const FixLarge({required super.held, required super.gap, required super.shareAfter, required super.perDay});
}

/// The one entry a fix posts: [kind] is *Spent* when money is missing and *Got* when hisaab
/// under-counted, for [amount] whole rupees (BR-18).
final class FixPost extends Equatable {
  const FixPost({required this.kind, required this.amount});

  final EntryKind kind;
  final Money amount;

  @override
  List<Object?> get props => <Object?>[kind, amount];
}
