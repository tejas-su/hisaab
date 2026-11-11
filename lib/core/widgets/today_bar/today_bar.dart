import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

import '../../design/hisaab_motion.dart';
import '../../design/hisaab_type.dart';
import '../../extensions/build_context_extensions.dart';
import 'today_bar_data.dart';
import 'today_bar_painter.dart';

/// The hero's picture of today: today's share as one bar, the yellow what's left and each
/// spend a bite out of it, with category names under the bites (SPEC BR-6, UI_DESIGN §5.2).
///
/// A change moves the yellow on the `standard` spring, uncovering a new bite beside it (D91,
/// D114). [fillIn] grows the yellow from empty on `calm` when the bar appears. Reduced motion
/// jumps to the new picture. The hero reads the whole card as one sentence, so the bar carries
/// no semantics of its own.
class TodayBar extends StatefulWidget {
  const TodayBar({super.key, required this.data, this.fillIn = false});

  final TodayBarData data;
  final bool fillIn;

  @override
  State<TodayBar> createState() => _TodayBarState();
}

class _TodayBarState extends State<TodayBar> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(vsync: this, value: widget.fillIn ? 0 : 1);
  late TodayBarData _from = widget.fillIn ? _empty(widget.data) : widget.data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_progress.value == 0 && !_progress.isAnimating) {
      _run(HisaabMotion.calm);
    }
  }

  @override
  void didUpdateWidget(TodayBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) {
      return;
    }
    _from = oldWidget.data;
    _progress.value = 0;
    _run(HisaabMotion.standard);
  }

  // why: a spring settles within its tolerance, not on 1; resting at exactly 1 keeps the next
  // dependency change from starting the move again.
  void _run(SpringDescription spring) {
    if (HisaabMotion.reduceMotion(context)) {
      _progress.value = 1;
      return;
    }
    _progress.animateWith(SpringSimulation(spring, 0, 1, 0)).whenCompleteOrCancel(_rest);
  }

  void _rest() {
    if (mounted) {
      _progress.value = 1;
    }
  }

  static TodayBarData _empty(TodayBarData data) => TodayBarData(style: data.style, bites: data.bites, tick: data.tick);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? names = HisaabType.regular(Theme.of(context).textTheme.labelSmall)?.copyWith(color: context.colors.displayInk2);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double nameLine = scaler.scale(names?.fontSize ?? 0) * (names?.height ?? 1);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _progress,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            size: Size.fromHeight(TodayBarPainter.barHeight + TodayBarPainter.nameGap + nameLine),
            painter: TodayBarPainter(
              from: _from,
              to: widget.data,
              progress: _progress.value.clamp(0, 1),
              names: names,
              textScaler: scaler,
              colors: TodayBarColors(
                signal: context.colors.signal,
                idle: context.colors.blockIdle,
                edge: context.colors.displayEdge,
                ink: context.colors.displayInk,
                ink2: context.colors.displayInk2,
                card: context.colors.display,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
