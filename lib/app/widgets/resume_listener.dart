import 'package:flutter/widgets.dart';

/// Calls [onResume] each time the app comes back to the foreground (SPEC BR-8).
class ResumeListener extends StatefulWidget {
  const ResumeListener({super.key, required this.onResume, required this.child});

  final VoidCallback onResume;
  final Widget child;

  @override
  State<ResumeListener> createState() => _ResumeListenerState();
}

class _ResumeListenerState extends State<ResumeListener> {
  late final AppLifecycleListener _listener = AppLifecycleListener(onResume: () => widget.onResume());

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
