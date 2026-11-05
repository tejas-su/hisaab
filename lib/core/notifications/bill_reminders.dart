import 'package:fpdart/fpdart.dart';

import 'bill_reminder.dart';

/// The due-day reminders for changing and card bills (spec §6, D126). A bonus on top of Home's
/// "How much?" line, which is the guarantee: some phones drop them.
///
/// No method ever throws; a failure is logged by the implementation and the app carries on.
abstract interface class BillReminders {
  /// Schedules every reminder in [upcoming] and removes every other one, pending or shown,
  /// unless its id is in [keep]. Completes once the system has them.
  Future<void> arm(List<BillReminder> upcoming, {required Set<int> keep});

  /// Asks Android for permission to post them; completes with true when it is given.
  Future<bool> requestPermission();

  /// The reminder whose tap started the app, or [None].
  Future<Option<BillReminderTap>> launchTap();

  /// Taps on a reminder while the app is running.
  Stream<BillReminderTap> get taps;
}
