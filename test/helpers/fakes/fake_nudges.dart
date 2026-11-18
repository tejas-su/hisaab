import 'dart:async';

import 'package:hisaab/core/notifications/nudge_notice.dart';
import 'package:hisaab/core/notifications/nudges.dart';

/// An in-memory [Nudges]: records what was armed and lets a test tap a nudge.
final class FakeNudges implements Nudges {
  FakeNudges({this.granted = true, this.launchedBy = false});

  /// What [requestPermission] answers.
  bool granted;

  /// What [launchedByNudge] answers.
  bool launchedBy;

  /// The nudges scheduled by the latest [arm].
  List<NudgeNotice> scheduled = <NudgeNotice>[];

  /// How many times [arm] ran.
  int arms = 0;

  /// How many times [requestPermission] was asked.
  int permissionAsks = 0;

  final StreamController<void> _taps = StreamController<void>.broadcast();

  /// Acts as if the user tapped a nudge.
  void tap() => _taps.add(null);

  @override
  Future<void> arm(List<NudgeNotice> upcoming) async {
    arms++;
    scheduled = upcoming;
  }

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return granted;
  }

  @override
  Future<bool> areEnabled() async => granted;

  @override
  Future<bool> launchedByNudge() async => launchedBy;

  @override
  Stream<void> get taps => _taps.stream;

  /// Closes the tap stream; call from a test's tear-down.
  Future<void> dispose() => _taps.close();
}
