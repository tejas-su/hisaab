import 'bill_reminder.dart';

/// Which listener a tapped notification belongs to, decided by its payload alone.
enum NotificationRoute {
  /// A `hisaab://bill/...` link: [BillReminderTap] handles it.
  bill,

  /// The `hisaab://nudge` link of a daily nudge.
  nudge,

  /// No payload, or one this app does not know.
  ignored;

  /// The payload every daily nudge carries.
  static const String nudgeLink = 'hisaab://nudge';

  /// Reads [payload] into the listener that owns it.
  static NotificationRoute of(String? payload) {
    if (payload == nudgeLink) return nudge;
    return BillReminderTap.parse(payload).isSome() ? bill : ignored;
  }
}
