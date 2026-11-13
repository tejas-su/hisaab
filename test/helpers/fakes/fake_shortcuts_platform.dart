import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

/// An in-memory [ShortcutsPlatform]: records what was published and asked, and lets a test tap
/// the widget, tile or shortcut.
final class FakeShortcutsPlatform implements ShortcutsPlatform {
  FakeShortcutsPlatform({
    this.pinWidgetSupported = true,
    this.tileSupported = true,
    this.launchedBy = const Option<LaunchAction>.none(),
  });

  /// What [canPinWidget] answers.
  bool pinWidgetSupported;

  /// What [canAddTile] answers.
  bool tileSupported;

  /// What [launchAction] answers once; it is gone after the first read.
  Option<LaunchAction> launchedBy;

  /// Every snapshot published, in order.
  final List<WidgetSnapshot> published = <WidgetSnapshot>[];

  /// How many times [pinWidget] and [addTile] were asked.
  int widgetPins = 0;
  int tileAdds = 0;

  /// When set, [pinWidget] and [addTile] wait for it, as Android's dialog is being asked for.
  Completer<void>? askGate;

  /// When set, the next [publish] waits for it, so a test can queue another publish behind it.
  Completer<void>? nextPublishGate;

  final StreamController<LaunchAction> _launches = StreamController<LaunchAction>.broadcast();

  /// Acts as if the user tapped something that asks for [action] while the app runs.
  void tap(LaunchAction action) => _launches.add(action);

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    final Completer<void>? gate = nextPublishGate;
    nextPublishGate = null;
    await gate?.future;
    published.add(snapshot);
  }

  @override
  Future<bool> canPinWidget() async => pinWidgetSupported;

  @override
  Future<void> pinWidget() async {
    await askGate?.future;
    widgetPins++;
  }

  @override
  Future<bool> canAddTile() async => tileSupported;

  @override
  Future<void> addTile() async {
    await askGate?.future;
    tileAdds++;
  }

  @override
  Future<Option<LaunchAction>> launchAction() async {
    final Option<LaunchAction> action = launchedBy;
    launchedBy = const Option<LaunchAction>.none();
    return action;
  }

  @override
  Stream<LaunchAction> get launches => _launches.stream;

  Future<void> dispose() => _launches.close();
}
