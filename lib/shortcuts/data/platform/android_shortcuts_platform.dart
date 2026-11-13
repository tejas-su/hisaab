import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../../domain/entities/launch_action.dart';
import '../../domain/entities/widget_snapshot.dart';
import '../../domain/repository/shortcuts_platform.dart';
import '../mapper/widget_snapshot_json.dart';

/// [ShortcutsPlatform] over the `hisaab/shortcuts` method channel that `MainActivity.kt` serves
/// (widget spec §3). Native code calls `launch` with a tap's URI while the app runs.
final class AndroidShortcutsPlatform implements ShortcutsPlatform {
  /// Listens on [channel] for taps; the app makes one, for as long as it runs.
  AndroidShortcutsPlatform([this._channel = const MethodChannel(channelName)]) {
    _channel.setMethodCallHandler(_onCall);
  }

  /// The channel's name, shared with `MainActivity.kt`.
  static const String channelName = 'hisaab/shortcuts';

  final MethodChannel _channel;

  // ignore: close_sinks, why: taps can come for as long as the app runs, so it is never closed.
  final StreamController<LaunchAction> _launches = StreamController<LaunchAction>.broadcast();

  @override
  Stream<LaunchAction> get launches => _launches.stream;

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'launch' && call.arguments is String) {
      LaunchAction.parse(call.arguments as String).map(_launches.add);
    }
  }

  @override
  Future<void> publish(WidgetSnapshot snapshot) => _quietly(
        'shortcuts.publish_failed',
        () => _channel.invokeMethod<void>('publish', jsonEncode(WidgetSnapshotJson.toJson(snapshot))),
        null,
      );

  @override
  Future<bool> canPinWidget() async => await _quietly('shortcuts.can_pin_failed', () => _channel.invokeMethod<bool>('canPinWidget'), false) ?? false;

  @override
  Future<void> pinWidget() => _quietly('shortcuts.pin_failed', () => _channel.invokeMethod<void>('pinWidget'), null);

  @override
  Future<bool> canAddTile() async => await _quietly('shortcuts.can_add_tile_failed', () => _channel.invokeMethod<bool>('canAddTile'), false) ?? false;

  @override
  Future<void> addTile() => _quietly('shortcuts.add_tile_failed', () => _channel.invokeMethod<void>('addTile'), null);

  @override
  Future<Option<LaunchAction>> launchAction() async =>
      LaunchAction.parse(await _quietly('shortcuts.launch_failed', () => _channel.invokeMethod<String>('launchAction'), null));

  // why: the widget and tile only open the app sooner; a channel error must never stop it, so it
  // is logged and the fallback is used.
  static Future<T?> _quietly<T>(String tag, Future<T?> Function() action, T? fallback) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, tag: tag);
      return fallback;
    }
  }
}
