import 'package:equatable/equatable.dart';

import '../../core/notifications/bill_reminder.dart';

/// What makes the app arm its bill reminders or answer a tap on one (spec §6, D126).
sealed class RemindersEvent extends Equatable {
  const RemindersEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The app opened past onboarding: open the bill whose reminder started it, then arm.
final class RemindersStarted extends RemindersEvent {
  const RemindersStarted();
}

/// Something changed (a write, a resume, an answer to the ask): arm the reminders again.
final class RemindersArmRequested extends RemindersEvent {
  const RemindersArmRequested();
}

/// The user tapped [tap]'s reminder while the app was running.
final class RemindersTapped extends RemindersEvent {
  const RemindersTapped(this.tap);

  final BillReminderTap tap;

  @override
  List<Object?> get props => <Object?>[tap];
}
