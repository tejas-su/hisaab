import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../ledger/ledger.dart';

/// What *Can I afford it?* knows about the user's money before they type anything (SPEC BR-24).
final class AffordContext extends Equatable {
  const AffordContext({
    required this.room,
    required this.days,
    required this.usual,
    required this.nextCycle,
    required this.existingSaving,
    required this.existingSetAside,
  });

  /// The next cycle's money after its bills and its savings' capped put-ins.
  final Money room;

  /// The length of [nextCycle] in days.
  final int days;

  /// Average typed *Spent* a day over the last finished, fully tracked cycle, floored to the rupee;
  /// [None] with no such cycle or a ₹0 average.
  final Option<Money> usual;

  /// The one full cycle after the current one.
  final PayCycle nextCycle;

  /// The active saving named like the item (case-insensitive), left out of [room] (D221).
  final Option<RecurringRule> existingSaving;

  /// What is set aside in [existingSaving]; [Money.zero] when there is none.
  final Money existingSetAside;

  @override
  List<Object?> get props => <Object?>[
    room,
    days,
    usual,
    nextCycle,
    existingSaving,
    existingSetAside,
  ];
}
