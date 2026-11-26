import 'package:material_ui/material_ui.dart';

import '../shell_destination.dart';

/// Owns the [ShellDestination] notifier of the main screen and hands it to [builder], so code
/// above the screen (the app shortcut, FR-WG-9) can switch the screen in view.
class ShellDestinationHost extends StatefulWidget {
  const ShellDestinationHost({super.key, required this.builder});

  final Widget Function(ValueNotifier<ShellDestination> destination) builder;

  @override
  State<ShellDestinationHost> createState() => _ShellDestinationHostState();
}

class _ShellDestinationHostState extends State<ShellDestinationHost> {
  final ValueNotifier<ShellDestination> _destination = ValueNotifier<ShellDestination>(ShellDestination.home);

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_destination);
}
