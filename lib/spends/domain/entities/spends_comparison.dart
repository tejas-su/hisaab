import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// The cycle shown against the cycle before (SPEC BR-21, FR-SP-3a): by the same day while it runs,
/// whole against whole once it is finished.
final class SpendsComparison extends Equatable {
  const SpendsComparison({required this.change, required this.wholeCycle});

  /// Under this far apart reads "Same as".
  static final Money sameWithin = Money.fromMajor(100);

  /// *Spent* in the cycle shown less the cycle before; negative when less was spent.
  final Money change;

  /// Whether whole cycles were compared ("than in September") rather than the same day ("than by
  /// this day in September").
  final bool wholeCycle;

  /// Under ₹100 apart, which reads as the same.
  bool get isSame => change.amountMinor.abs() < sameWithin.amountMinor;

  @override
  List<Object?> get props => <Object?>[change, wholeCycle];
}
