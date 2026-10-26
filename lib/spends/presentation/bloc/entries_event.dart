import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../ledger/ledger.dart';

/// What happens on *Every entry*.
sealed class EntriesEvent extends Equatable {
  const EntriesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The page opened, Try again was tapped, or the ledger changed; read the cycle's entries.
final class EntriesLoadRequested extends EntriesEvent {
  const EntriesLoadRequested();
}

/// The user tapped a category chip; [categoryId] is none for *All*.
final class EntriesFilterChanged extends EntriesEvent {
  const EntriesFilterChanged(this.categoryId);

  final Option<int> categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// The user swiped [entry] away.
final class EntriesDeleteRequested extends EntriesEvent {
  const EntriesDeleteRequested(this.entry);

  final Entry entry;

  @override
  List<Object?> get props => <Object?>[entry];
}

/// The user tapped Undo after deleting [entry].
final class EntriesUndoRequested extends EntriesEvent {
  const EntriesUndoRequested(this.entry);

  final Entry entry;

  @override
  List<Object?> get props => <Object?>[entry];
}

/// A row's swipe crossed the delete threshold.
final class EntriesSwipeThresholdReached extends EntriesEvent {
  const EntriesSwipeThresholdReached();
}
