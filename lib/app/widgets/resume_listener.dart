import 'package:flutter/widgets.dart';

/// Calls [onResume] each time the app comes back to the foreground (SPEC BR-8).
class ResumeListener extends StatefulWidget {
  const ResumeListener({super.key, required this.onResume, required this.child});

  final VoidCallback onResume;
  final Widget child;

  @override
  State<ResumeListener> createState() => _ResumeListenerState();
}

class _ResumeListenerState extends State<ResumeListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
