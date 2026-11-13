import 'package:fpdart/fpdart.dart';

import '../entities/launch_action.dart';
import '../entities/widget_snapshot.dart';

/// Android's side of the widget, the Quick Settings tile and the app shortcut (SPEC FR-WG,
/// FR-SE-6). No method ever throws: a failure is logged by the implementation and the app carries on.
abstract interface class ShortcutsPlatform {
  /// Stores [snapshot] for the widget and redraws every placed widget. Completes once stored.
  Future<void> publish(WidgetSnapshot snapshot);

  /// Whether the launcher can add the widget for the app (`isRequestPinAppWidgetSupported`).
  Future<bool> canPinWidget();

  /// Opens the launcher's own add-widget dialog; completes when it has been asked.
  Future<void> pinWidget();

  /// Whether Android can add the tile for the app (Android 13 and later).
  Future<bool> canAddTile();

  /// Opens Android's own add-tile dialog; completes when it has been asked.
  Future<void> addTile();

  /// The action whose tap started the app, or [None]; read once, then it is gone.
  Future<Option<LaunchAction>> launchAction();

  /// Taps on the widget, tile or shortcut while the app is running.
  Stream<LaunchAction> get launches;
}
