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
