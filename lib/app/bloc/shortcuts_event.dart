import 'package:equatable/equatable.dart';

import '../../shortcuts/shortcuts.dart';

/// What makes the app write the widget's snapshot or follow a widget, tile or shortcut tap
/// (SPEC FR-WG-4 to FR-WG-7).
sealed class ShortcutsEvent extends Equatable {
  const ShortcutsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The app started: hold the tap that started it, if any, for the first screen.
final class ShortcutsStarted extends ShortcutsEvent {
  const ShortcutsStarted();
}

/// Something the widget shows changed (a write, the look, a resume, onboarding, a restore or
/// *Delete everything*): write the snapshot again.
final class ShortcutsPublishRequested extends ShortcutsEvent {
  const ShortcutsPublishRequested();
}

/// The user tapped the widget, tile or shortcut while the app was running.
final class ShortcutsLaunched extends ShortcutsEvent {
  const ShortcutsLaunched(this.action);

  final LaunchAction action;

  @override
  List<Object?> get props => <Object?>[action];
}

/// The screen in view followed the pending launch.
final class ShortcutsLaunchHandled extends ShortcutsEvent {
  const ShortcutsLaunchHandled();
}
