import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_motion.dart';

/// The *Can I afford it?* answer rising into place as it appears (UI_DESIGN 5.4a): it fades in and
/// slides up [rise] of its own height on [HisaabMotion.standard], like Spends' pages. With reduced
/// motion it only crossfades, in [HisaabMotion.reducedCrossfade], and never moves.
class AffordRiseIn extends StatefulWidget {
  const AffordRiseIn({super.key, required this.child});

  final Widget child;

  /// How far the answer starts below its place, as a fraction of its own height.
  static const double rise = 0.25;

  @override
  State<AffordRiseIn> createState() => _AffordRiseInState();
}

class _AffordRiseInState extends State<AffordRiseIn> with SingleTickerProviderStateMixin {
  // why: preserve, so reduced motion still gets its 150 ms crossfade rather than a cut.
  late final AnimationController _shown = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // why: it rises once, when the answer first appears; a later MediaQuery change doesn't replay it.
    if (_shown.status != AnimationStatus.dismissed) {
      return;
    }
    if (HisaabMotion.reduceMotion(context)) {
      _shown.animateTo(1, duration: HisaabMotion.reducedCrossfade);
      return;
    }
    _shown.animateWith(SpringSimulation(HisaabMotion.standard, 0, 1, 0, snapToEnd: true));
  }

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (HisaabMotion.reduceMotion(context)) {
      return FadeTransition(opacity: _shown, child: widget.child);
    }
    return FadeTransition(
      opacity: _shown,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, AffordRiseIn.rise), end: Offset.zero).animate(_shown),
        child: widget.child,
      ),
    );
  }
}
