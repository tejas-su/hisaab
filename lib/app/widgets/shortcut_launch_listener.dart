import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shortcuts/shortcuts.dart';
import '../bloc/shortcuts_bloc.dart';
import '../bloc/shortcuts_event.dart';
import '../bloc/shortcuts_state.dart';

/// Follows a widget, tile or shortcut tap on the root screen in view (widget spec §8): one
/// pending when the screen is first built (the tap that started the app) and each one after.
///
/// Needs a [ShortcutsBloc] above it. The tap is marked handled before [onLaunch] runs, so a tray
/// that [onLaunch] keeps open never holds a second tap back.
class ShortcutLaunchListener extends StatefulWidget {
  const ShortcutLaunchListener({super.key, required this.onLaunch, required this.child});

  /// Opens what the tap asked for on this screen.
  final ValueChanged<LaunchAction> onLaunch;
  final Widget child;

  @override
  State<ShortcutLaunchListener> createState() => _ShortcutLaunchListenerState();
}

class _ShortcutLaunchListenerState extends State<ShortcutLaunchListener> {
  @override
  void initState() {
    super.initState();
    // why: a tap that started the app is pending before this screen exists, and a listener only
    // hears later changes, so the first frame reads it once.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _follow(context.read<ShortcutsBloc>().state);
      }
    });
  }

  void _follow(ShortcutsState state) {
    if (state case ShortcutsLaunchPending(:final LaunchAction action)) {
      context.read<ShortcutsBloc>().add(const ShortcutsLaunchHandled());
      widget.onLaunch(action);
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ShortcutsBloc, ShortcutsState>(
        listener: (BuildContext _, ShortcutsState state) => _follow(state),
        child: widget.child,
      );
}
