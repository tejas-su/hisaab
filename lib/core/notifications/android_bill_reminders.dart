import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fpdart/fpdart.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/gen/app_localizations.dart';
import '../logging/app_logger.dart';
import 'bill_reminder.dart';
import 'bill_reminders.dart';

/// [BillReminders] on Android, through `flutter_local_notifications` (spec §6, D126).
///
/// Inexact (`inexactAllowWhileIdle`), so no exact-alarm permission is needed; the plugin's boot
/// receiver re-arms them after a restart. The text comes from the ARB, and a locked screen
/// hides it.
final class AndroidBillReminders implements BillReminders {
  AndroidBillReminders._(this._plugin, this._strings, this._taps);

  /// Starts the plugin; call once before `runApp`. Never throws.
  static Future<AndroidBillReminders> start() async {
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    // ignore: close_sinks, why: taps can come for as long as the app runs, so it is never closed.
    final StreamController<BillReminderTap> taps = StreamController<BillReminderTap>.broadcast();
    await _quietly('reminders.start_failed', () => plugin.initialize(
          settings: const InitializationSettings(android: AndroidInitializationSettings(_icon)),
          onDidReceiveNotificationResponse: (NotificationResponse response) => BillReminderTap.parse(response.payload).map(taps.add),
        ));
    return AndroidBillReminders._(plugin, lookupAppLocalizations(_locale), taps);
  }

  static const String _icon = 'ic_launcher_monochrome';
  static const String _channel = 'bill_reminders';
  static const Locale _locale = Locale('en', 'IN');

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLocalizations _strings;
  final StreamController<BillReminderTap> _taps;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Stream<BillReminderTap> get taps => _taps.stream;

  @override
  Future<void> arm(List<BillReminder> upcoming, {required Set<int> keep}) => _quietly('reminders.arm_failed', () async {
        final Set<int> wanted = <int>{...keep, ...upcoming.map((BillReminder r) => r.id)};
        final Set<int> current = <int>{
          ...(await _plugin.pendingNotificationRequests()).map((PendingNotificationRequest p) => p.id),
          ...(await _android?.getActiveNotifications() ?? const <ActiveNotification>[])
              .where((ActiveNotification a) => a.channelId == _channel)
              .map((ActiveNotification a) => a.id)
              .whereType<int>(),
        };
        for (final int stale in current.difference(wanted)) {
          await _plugin.cancel(id: stale);
        }
        // why: scheduling an id again replaces it, so a renamed bill gets its new name.
        for (final BillReminder reminder in upcoming) {
          await _schedule(reminder);
        }
      });

  Future<void> _schedule(BillReminder reminder) => _plugin.zonedSchedule(
        id: reminder.id,
        // why: a one-off instant needs no time-zone database; UTC is the same moment as 9:00 local.
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
        notificationDetails: NotificationDetails(android: _details),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: reminder.isCard ? _strings.reminderTitleCard(reminder.billName) : _strings.reminderTitleVaries(reminder.billName),
        body: _strings.reminderText,
        payload: reminder.tap.link,
      );

  AndroidNotificationDetails get _details => AndroidNotificationDetails(
        _channel,
        _strings.reminderChannel,
        channelDescription: _strings.reminderChannelDescription,
        category: AndroidNotificationCategory.reminder,
        // why: a locked screen shows only the app's name, never the bill (spec §6, D126).
        visibility: NotificationVisibility.private,
      );

  @override
  Future<bool> requestPermission() async {
    bool granted = false;
    await _quietly('reminders.permission_failed', () async => granted = await _android?.requestNotificationsPermission() ?? false);
    return granted;
  }

  @override
  Future<Option<BillReminderTap>> launchTap() async {
    Option<BillReminderTap> tap = const Option<BillReminderTap>.none();
    await _quietly('reminders.launch_failed', () async {
      final NotificationAppLaunchDetails? details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        tap = BillReminderTap.parse(details?.notificationResponse?.payload);
      }
    });
    return tap;
  }

  // why: reminders are a bonus on top of Home's line (spec §6); a plugin error must never stop
  // the app, so it is logged and dropped.
  static Future<void> _quietly(String tag, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, tag: tag);
    }
  }
}
