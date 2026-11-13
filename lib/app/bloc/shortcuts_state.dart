import 'package:equatable/equatable.dart';

import '../../shortcuts/shortcuts.dart';

/// Whether a widget, tile or shortcut tap is waiting for the screen in view to follow it.
sealed class ShortcutsState extends Equatable {
  const ShortcutsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing to follow.
final class ShortcutsIdle extends ShortcutsState {
  const ShortcutsIdle();
}

/// A tap asked for [action]; it stays until the screen in view follows it, so a tap that
/// started the app waits for that screen to be built.
final class ShortcutsLaunchPending extends ShortcutsState {
  const ShortcutsLaunchPending(this.action);

  final LaunchAction action;

  @override
  List<Object?> get props => <Object?>[action];
}
