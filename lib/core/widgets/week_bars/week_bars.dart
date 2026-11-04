import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../design/hisaab_motion.dart';
import '../../extensions/build_context_extensions.dart';
import 'week_bars_data.dart';
import 'week_bars_painter.dart';

/// The hero's *This week* bars: Monday to Sunday, each with its share tick (SPEC BR-6a).
///
/// They rise from the baseline when they appear, today's first, on the `standard` spring; with
/// reduced motion they are drawn at once (the hero crossfades instead). The hero reads the whole
/// card as one sentence, so the bars carry no semantics of their own.
class WeekBars extends StatefulWidget {
  const WeekBars({super.key, required this.data, required this.height});

  final WeekBarsData data;

  /// The tallest value in the week reaches this height.
  final double height;

  @override
  State<WeekBars> createState() => _WeekBarsState();
}

class _WeekBarsState extends State<WeekBars> with SingleTickerProviderStateMixin {
  late final AnimationController _growth = AnimationController.unbounded(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_growth.isAnimating || _growth.value == 1) {
      return;
    }
    if (HisaabMotion.reduceMotion(context)) {
      _growth.value = 1;
      return;
    }
    // why: a spring settles within its tolerance, not on 1; resting at exactly 1 keeps a later
    // dependency change from starting the rise again.
    _growth.animateWith(SpringSimulation(HisaabMotion.standard, _growth.value, 1, 0)).whenCompleteOrCancel(_rest);
  }

  void _rest() {
    if (mounted) {
      _growth.value = 1;
    }
  }

  @override
  void dispose() {
    _growth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _growth,
            builder: (BuildContext context, Widget? _) => CustomPaint(
              size: Size.fromHeight(widget.height),
              painter: WeekBarsPainter(
                data: widget.data,
                growth: _growth.value.clamp(0, 1),
                colors: WeekBarsColors(
                  past: context.colors.displayInk2,
                  signal: context.colors.signal,
                  edge: context.colors.displayEdge,
                  tick: context.colors.displayInk,
                  notch: context.colors.display,
                  idle: context.colors.blockIdle,
                ),
              ),
            ),
          ),
        ),
      );
}
