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

/// The bills (or savings), soonest first. [undo] holds one just deleted, so the page can offer
/// Undo once; [saved] is the savings list's "put in" total, [None] for bills or before any save.
final class BillsReady extends BillsState {
  const BillsReady({
    required this.bills,
    this.undo = const Option<RecurringRule>.none(),
    this.saved = const Option<SavedTotal>.none(),
  });

  final List<RecurringRule> bills;
  final Option<RecurringRule> undo;
  final Option<SavedTotal> saved;

  /// Returns a copy with the given fields replaced; [undo] and [saved] reset unless passed.
  BillsReady copyWith({
    List<RecurringRule>? bills,
    Option<RecurringRule> undo = const Option<RecurringRule>.none(),
    Option<SavedTotal> saved = const Option<SavedTotal>.none(),
  }) =>
      BillsReady(bills: bills ?? this.bills, undo: undo, saved: saved);

  @override
  List<Object?> get props => <Object?>[bills, undo, saved];
}

/// Loading failed; a quiet message with Try again.
final class BillsFailed extends BillsState {
  const BillsFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
