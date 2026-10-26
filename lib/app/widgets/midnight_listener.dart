import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/time/clock.dart';

/// Calls [onNewDay] at each local midnight while the app is open (SPEC BR-8), timed by [clock].
///
/// The timer is set again on every resume, since a sleeping phone or a clock change makes it
/// late or early.
class MidnightListener extends StatefulWidget {
  const MidnightListener({super.key, required this.clock, required this.onNewDay, required this.child});

  final Clock clock;
  final VoidCallback onNewDay;
  final Widget child;

  // why: lands safely past midnight, so "today" has already changed when [onNewDay] runs.
  static const Duration _margin = Duration(seconds: 1);

  @override
  State<MidnightListener> createState() => _MidnightListenerState();
}

class _MidnightListenerState extends State<MidnightListener> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.clock.untilTomorrow() + MidnightListener._margin, _newDay);
  }

  void _newDay() {
    widget.onNewDay();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
