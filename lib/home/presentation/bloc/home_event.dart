import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// What happens on Home.
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Home opened or resumed, midnight passed, Try again was tapped, or the money changed;
/// work out today again.
final class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

/// The user tapped the hero to flip between *Today* and *This week*.
final class HomeWeekToggled extends HomeEvent {
  const HomeWeekToggled();
}

/// The user swiped [entry] away in the Today list.
final class HomeDeleteRequested extends HomeEvent {
  const HomeDeleteRequested(this.entry);

  final Entry entry;

  @override
  List<Object?> get props => <Object?>[entry];
}

/// The user tapped Undo after deleting [entry].
final class HomeUndoRequested extends HomeEvent {
  const HomeUndoRequested(this.entry);

  final Entry entry;

  @override
  List<Object?> get props => <Object?>[entry];
}

/// The user tapped *Delete bill* on [rule]'s bill sheet, opened from the due-soon row (D118).
final class HomeBillDeleteRequested extends HomeEvent {
  const HomeBillDeleteRequested(this.rule);

  final RecurringRule rule;

  @override
  List<Object?> get props => <Object?>[rule];
}

/// The user tapped Undo after deleting the bill [rule].
final class HomeBillUndoRequested extends HomeEvent {
  const HomeBillUndoRequested(this.rule);

  final RecurringRule rule;

  @override
  List<Object?> get props => <Object?>[rule];
}

/// A row's swipe crossed the delete threshold.
final class HomeSwipeThresholdReached extends HomeEvent {
  const HomeSwipeThresholdReached();
}

/// The Add tray opened over Home; Home holds its numbers until [HomeTrayClosed].
final class HomeTrayOpened extends HomeEvent {
  const HomeTrayOpened();
}

/// The Add tray's exit animation ended, so Home is in full view again.
final class HomeTrayClosed extends HomeEvent {
  const HomeTrayClosed();
}
