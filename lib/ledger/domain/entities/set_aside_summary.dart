import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// How much of the money put into the active savings is still set aside (BR-19, D120).
final class SetAsideSummary extends Equatable {
  const SetAsideSummary({
    this.perSaving = const <int, Money>{},
    this.stillSetAside = Money.zero,
    this.anyUse = false,
  });

  /// Each active saving's set-aside by its rule id, never below ₹0. A saving with nothing set
  /// aside is here too.
  final Map<int, Money> perSaving;

  /// The sum of [perSaving]: what the Savings list footer calls "still set aside".
  final Money stillSetAside;

  /// Whether any *Used* entry exists, even one whose saving is gone, so the footer may say
  /// "Nothing is set aside now." (AC-Y4, E98).
  final bool anyUse;

  @override
  List<Object?> get props => <Object?>[perSaving, stillSetAside, anyUse];
}
