import 'package:equatable/equatable.dart';

import '../../domain/entities/insight.dart';

/// What happens on Spends.
sealed class SpendsEvent extends Equatable {
  const SpendsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// An event that changes which cycle is shown, or reloads it; the newest one wins.
sealed class SpendsCycleEvent extends SpendsEvent {
  const SpendsCycleEvent();
}

/// Spends opened or resumed, midnight passed, Try again was tapped, or the ledger changed;
/// load the cycle being shown.
final class SpendsLoadRequested extends SpendsCycleEvent {
  const SpendsLoadRequested();
}

/// The user tapped ‹ for the cycle before.
final class SpendsEarlierPressed extends SpendsCycleEvent {
  const SpendsEarlierPressed();
}

/// The user tapped › for the cycle after.
final class SpendsLaterPressed extends SpendsCycleEvent {
  const SpendsLaterPressed();
}

/// The user picked a cycle in the months strip and tapped *Open* (FR-SP-8).
final class SpendsCyclePicked extends SpendsCycleEvent {
  const SpendsCyclePicked(this.cyclesBack);

  /// 0 for the current cycle, 1 for the one before, and so on.
  final int cyclesBack;

  @override
  List<Object?> get props => <Object?>[cyclesBack];
}

/// The user accepted "Use these limits?" for [offer] (BR-12).
final class SpendsLimitsAccepted extends SpendsEvent {
  const SpendsLimitsAccepted(this.offer);

  final LimitOffer offer;

  @override
  List<Object?> get props => <Object?>[offer];
}
