import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/hisaab_motion.dart';

/// Shakes [child] sideways each time [trigger] changes: the "no" for a rejected key (FR-AD-2).
///
/// Skipped under reduced motion; the reject haptic still says no.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  /// Any value; a change starts one shake.
  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  static const double _distance = 8;
  static const int _swings = 3;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: HisaabMotion.numberRoll);

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !HisaabMotion.reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (BuildContext context, Widget? child) {
          final double t = _controller.value;
          final double dx = math.sin(t * math.pi * 2 * _swings) * _distance * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}
