import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../ledger/ledger.dart';

/// What the Fixed bills screen shows.
sealed class BillsState extends Equatable {
  const BillsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load; nothing to show yet.
final class BillsLoading extends BillsState {
  const BillsLoading();
}

/// The bills, soonest first. [undo] holds a bill just deleted, so the page can offer Undo once.
final class BillsReady extends BillsState {
  const BillsReady({required this.bills, this.undo = const Option<RecurringRule>.none()});

  final List<RecurringRule> bills;
  final Option<RecurringRule> undo;

  /// Returns a copy with the given fields replaced; [undo] resets unless passed.
  BillsReady copyWith({List<RecurringRule>? bills, Option<RecurringRule> undo = const Option<RecurringRule>.none()}) =>
      BillsReady(bills: bills ?? this.bills, undo: undo);

  @override
  List<Object?> get props => <Object?>[bills, undo];
}

/// Loading failed; a quiet message with Try again.
final class BillsFailed extends BillsState {
  const BillsFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
