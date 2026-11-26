import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../ledger/ledger.dart';

/// A saving that *Start saving* wrote (SPEC BR-24, D220): the saved [rule], and the same-name
/// saving as it was before, [previous], when it changed one instead of making one (D221).
final class SavingStarted extends Equatable {
  const SavingStarted({required this.rule, required this.previous});

  final RecurringRule rule;

  /// [None] for a new saving; otherwise the saving before its amount and target changed.
  final Option<RecurringRule> previous;

  @override
  List<Object?> get props => <Object?>[rule, previous];
}
