import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// What happens on the Fixed bills screen.
sealed class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The screen opened, Try again was tapped, or a bill changed elsewhere; read the bills.
final class BillsLoadRequested extends BillsEvent {
  const BillsLoadRequested();
}

/// The user swiped [bill] away.
final class BillsDeleteRequested extends BillsEvent {
  const BillsDeleteRequested(this.bill);

  final RecurringRule bill;

  @override
  List<Object?> get props => <Object?>[bill];
}

/// The user tapped Undo after deleting [bill].
final class BillsUndoRequested extends BillsEvent {
  const BillsUndoRequested(this.bill);

  final RecurringRule bill;

  @override
  List<Object?> get props => <Object?>[bill];
}

/// A row's swipe crossed the delete threshold.
final class BillsSwipeThresholdReached extends BillsEvent {
  const BillsSwipeThresholdReached();
}

/// A *Used some of it* save finished on a saving's sheet opened from this list; the page offers Undo
/// for it (AC-Y9).
final class BillsUsedDone extends BillsEvent {
  const BillsUsedDone(this.outcome);

  final UsedOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// The user tapped Undo after a *Used* save: delete the entry, which sets the amount aside again.
final class BillsUsedUndoRequested extends BillsEvent {
  const BillsUsedUndoRequested(this.entry);

  final Entry entry;

  @override
  List<Object?> get props => <Object?>[entry];
}
