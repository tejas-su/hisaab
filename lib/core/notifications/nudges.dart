import 'nudge_notice.dart';

/// The daily nudge notifications (BR-22). No method throws; a failure is logged and dropped.
abstract interface class Nudges {
  /// Schedules [upcoming] and removes every other pending or shown nudge.
  Future<void> arm(List<NudgeNotice> upcoming);

  /// Asks the system for the notification permission; true when it is granted, false when
  /// refused, turned off or unavailable.
  Future<bool> requestPermission();

  /// Whether the phone currently allows notifications, read without ever showing a prompt.
  Future<bool> areEnabled();

  /// Emits each time the user taps a nudge while the app is running.
  Stream<void> get taps;

  /// Whether a nudge tap started the app from closed.
  Future<bool> launchedByNudge();
}
