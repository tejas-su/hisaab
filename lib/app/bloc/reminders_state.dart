import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../ledger/ledger.dart';

/// What the reminders ask the screen to do.
sealed class RemindersState extends Equatable {
  const RemindersState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing to show.
final class RemindersIdle extends RemindersState {
  const RemindersIdle();
}

/// A reminder was tapped: go to Home, then open [bill]'s amount sheet; [None] when the bill no
/// longer waits (it was entered, skipped or deleted), so only Home shows.
final class RemindersBillOpened extends RemindersState {
  const RemindersBillOpened(this.bill);

  final Option<Occurrence> bill;

  @override
  List<Object?> get props => <Object?>[bill];
}
