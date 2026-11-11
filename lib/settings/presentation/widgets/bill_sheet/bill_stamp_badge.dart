import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_motion.dart';
import '../../../../core/extensions/build_context_extensions.dart';

/// The bill's stamp, "Due in 3 days" or "Went out 5 Oct": straight letter-spaced text in a 2dp
/// `displayInk2` edge (D118).
///
/// It lands with a squash 260 ms after it first shows, on the flick spring; with reduced
/// motion it fades in over 150 ms instead.
class BillStampBadge extends StatefulWidget {
  const BillStampBadge({super.key, required this.text});

  final String text;

  @override
  State<BillStampBadge> createState() => _BillStampState();
}

class _BillStampState extends State<BillStampBadge> with SingleTickerProviderStateMixin {
  static const Duration _delay = Duration(milliseconds: 260);
  static const double _landingScale = 1.25;
  static const double _tracking = 1.2;

  late final AnimationController _land = AnimationController.unbounded(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (HisaabMotion.reduceMotion(context)) {
      _land.animateTo(1, duration: HisaabMotion.reducedCrossfade);
      return;
    }
    _land.animateWith(_DelayedSimulation(SpringSimulation(HisaabMotion.flick, 0, 1, 0), delay: _delay));
  }

  @override
  void dispose() {
    _land.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.colors.displayInk2;
    final Widget stamp = Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: 2),
        borderRadius: BorderRadius.circular(HisaabRadii.block),
      ),
      child: Text(widget.text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ink, letterSpacing: _tracking)),
    );
    final Animation<double> shown = _land.drive(const _Clamped());
    if (HisaabMotion.reduceMotion(context)) {
      return FadeTransition(opacity: shown, child: stamp);
    }
    return FadeTransition(
      opacity: shown,
      child: ScaleTransition(
        key: const ValueKey<String>('bill-stamp-squash'),
        scale: _land.drive(Tween<double>(begin: _landingScale, end: 1)),
        child: stamp,
      ),
    );
  }
}

/// Keeps the spring's overshoot out of the opacity.
class _Clamped extends Animatable<double> {
  const _Clamped();

  @override
  double transform(double t) => t.clamp(0, 1);
}

/// Holds [inner] at its start for [delay], then runs it.
class _DelayedSimulation extends Simulation {
  _DelayedSimulation(this.inner, {required Duration delay}) : _delay = delay.inMicroseconds / Duration.microsecondsPerSecond;

  final Simulation inner;
  final double _delay;

  double _local(double time) => time < _delay ? 0 : time - _delay;

  @override
  double x(double time) => inner.x(_local(time));

  @override
  double dx(double time) => time < _delay ? 0 : inner.dx(_local(time));

  @override
  bool isDone(double time) => time >= _delay && inner.isDone(_local(time));
}
