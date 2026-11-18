import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/gen/app_localizations.dart';
import '../logging/app_logger.dart';
import 'notification_hub.dart';
import 'notification_route.dart';
import 'nudge_notice.dart';
import 'nudge_text.dart';
import 'nudges.dart';

/// [Nudges] on Android, through the shared [NotificationHub] (BR-22).
///
/// Inexact (`inexactAllowWhileIdle`), so no exact-alarm permission is needed. A locked screen
/// hides the text, and it never carries an amount or a note.
final class AndroidNudges implements Nudges {
  /// Subscribes to [hub]'s responses for the app's lifetime to emit [taps]. [now] is the clock
  /// used to skip notices already in the past.
  AndroidNudges(this._hub, {DateTime Function() now = DateTime.now})
      // ignore: prefer_initializing_formals, why: a named parameter cannot be private.
      : _now = now,
        _strings = lookupAppLocalizations(_locale) {
    // ignore: cancel_subscriptions, why: it lives as long as the app.
    _hub.responses
        .where((NotificationResponse r) => NotificationRoute.of(r.payload) == NotificationRoute.nudge)
        .listen((_) => _taps.add(null));
  }

  static const String _channel = 'daily_nudge';
  static const Locale _locale = Locale('en', 'IN');

  final NotificationHub _hub;
  final DateTime Function() _now;
  final AppLocalizations _strings;
  // ignore: close_sinks, why: taps can come for as long as the app runs, so it is never closed.
  final StreamController<void> _taps = StreamController<void>.broadcast();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _hub.plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Stream<void> get taps => _taps.stream;

  @override
  Future<void> arm(List<NudgeNotice> upcoming) => _quietly('nudges.arm_failed', () async {
        final Set<int> wanted = upcoming.map((NudgeNotice n) => n.id).toSet();
        final Set<int> current = <int>{
          ...(await _hub.plugin.pendingNotificationRequests())
              .where((PendingNotificationRequest p) => p.payload == NotificationRoute.nudgeLink)
              .map((PendingNotificationRequest p) => p.id),
          ...(await _android?.getActiveNotifications() ?? const <ActiveNotification>[])
              .where((ActiveNotification a) => a.channelId == _channel)
              .map((ActiveNotification a) => a.id)
              .whereType<int>(),
        };
        for (final int stale in current.difference(wanted)) {
          await _hub.plugin.cancel(id: stale);
        }
        // why: scheduling an id again replaces it, so re-arming never shows two.
        final DateTime now = _now();
        for (final NudgeNotice notice in upcoming.where((NudgeNotice n) => n.isAfter(now))) {
          // why: one notice the plugin refuses must not stop the rest being scheduled.
          await _quietly('nudges.schedule_failed', () => _schedule(notice));
        }
      });

  Future<void> _schedule(NudgeNotice notice) {
    final ({String title, String body}) text = NudgeText.of(_strings, notice);
    return _hub.plugin.zonedSchedule(
        id: notice.id,
        // why: a one-off instant needs no time-zone database; UTC is the same moment as local.
        scheduledDate: tz.TZDateTime.from(notice.at, tz.UTC),
        notificationDetails: NotificationDetails(android: _details),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: text.title,
        body: text.body,
        payload: NotificationRoute.nudgeLink,
      );
  }

  AndroidNotificationDetails get _details => AndroidNotificationDetails(
        _channel,
        _strings.nudgeChannel,
        channelDescription: _strings.nudgeChannelDescription,
        category: AndroidNotificationCategory.reminder,
        // why: a locked screen shows only the app's name, never the category.
        visibility: NotificationVisibility.private,
      );

  @override
  Future<bool> requestPermission() async {
    bool granted = false;
    await _quietly('nudges.permission_failed', () async => granted = await _android?.requestNotificationsPermission() ?? false);
    return granted;
  }

  @override
  Future<bool> areEnabled() async {
    bool enabled = false;
    await _quietly('nudges.enabled_failed', () async => enabled = await _android?.areNotificationsEnabled() ?? false);
    return enabled;
  }

  @override
  Future<bool> launchedByNudge() async {
    final NotificationAppLaunchDetails? details = await _hub.launchDetails();
    return (details?.didNotificationLaunchApp ?? false) &&
        NotificationRoute.of(details?.notificationResponse?.payload) == NotificationRoute.nudge;
  }

  // why: a nudge is a bonus; a plugin error (or a refused permission, E122) must never stop the
  // app or the arming, so it is logged and dropped.
  static Future<void> _quietly(String tag, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, tag: tag);
    }
  }
}
