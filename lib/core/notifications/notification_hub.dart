import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logging/app_logger.dart';

/// The one owner of the notification plugin.
///
/// why: the plugin has a single instance and a second `initialize` would replace the first
/// one's response callbacks, so only the hub initialises it; bill reminders and nudges share it.
final class NotificationHub {
  NotificationHub._(this.plugin, this._responses);

  /// Initialises the plugin; call once before `runApp`. Never throws.
  static Future<NotificationHub> start() async {
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    // ignore: close_sinks, why: taps can come for as long as the app runs, so it is never closed.
    final StreamController<NotificationResponse> responses = StreamController<NotificationResponse>.broadcast();
    try {
      await plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings(_icon)),
        onDidReceiveNotificationResponse: responses.add,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, tag: 'notifications.start_failed');
    }
    return NotificationHub._(plugin, responses);
  }

  static const String _icon = 'ic_launcher_monochrome';

  /// The shared plugin; never call `initialize` on it.
  final FlutterLocalNotificationsPlugin plugin;
  final StreamController<NotificationResponse> _responses;

  /// Every notification tap or action while the app runs; never errors or completes.
  Stream<NotificationResponse> get responses => _responses.stream;

  /// How the app was launched, or null when that cannot be read. Never throws.
  Future<NotificationAppLaunchDetails?> launchDetails() async {
    try {
      return await plugin.getNotificationAppLaunchDetails();
    } on Object catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, tag: 'notifications.launch_failed');
      return null;
    }
  }
}
