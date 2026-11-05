import 'dart:async';

import 'package:expense_tracker/core/notifications/bill_reminder.dart';
import 'package:expense_tracker/core/notifications/bill_reminders.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [BillReminders]: records what was armed and lets a test tap a reminder.
final class FakeBillReminders implements BillReminders {
  FakeBillReminders({this.granted = true, this.launchedBy = const Option<BillReminderTap>.none()});

  /// What [requestPermission] answers.
  bool granted;

  /// What [launchTap] answers.
  Option<BillReminderTap> launchedBy;

  /// The reminders scheduled by the latest [arm].
  List<BillReminder> scheduled = <BillReminder>[];

  /// The ids the latest [arm] kept.
  Set<int> kept = <int>{};

  /// How many times [arm] ran.
  int arms = 0;

  /// How many times [requestPermission] was asked.
  int permissionAsks = 0;

  final StreamController<BillReminderTap> _taps = StreamController<BillReminderTap>.broadcast();

  /// Acts as if the user tapped the reminder for [tap].
  void tapOn(BillReminderTap tap) => _taps.add(tap);

  @override
  Future<void> arm(List<BillReminder> upcoming, {required Set<int> keep}) async {
    arms++;
    scheduled = upcoming;
    kept = keep;
  }

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return granted;
  }

  @override
  Future<Option<BillReminderTap>> launchTap() async => launchedBy;

  @override
  Stream<BillReminderTap> get taps => _taps.stream;

  Future<void> dispose() => _taps.close();
}
