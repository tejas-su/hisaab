import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../design/hisaab_motion.dart';
import '../../extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'day_blocks_data.dart';
import 'day_blocks_painter.dart';

/// The hero's picture: one block per day until payday, today's block draining as money is
/// spent (UI_DESIGN §1, SPEC BR-6).
///
/// Fill and heights move on the `standard` spring; [assemble] slides the blocks in once on the
/// `calm` spring (after onboarding). Reduced motion jumps straight to the new values. The row
/// is one semantics node with [semanticLabel]; the blocks themselves are not announced.
class DayBlocks extends StatefulWidget {
  const DayBlocks({super.key, required this.data, required this.semanticLabel, this.height = 40, this.assemble = false});

  final DayBlocksData data;
  final String semanticLabel;
  final double height;
  final bool assemble;

  @override
  State<DayBlocks> createState() => _DayBlocksState();
}

class _DayBlocksState extends State<DayBlocks> with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController.unbounded(vsync: this, value: widget.data.todayFill);
  late final AnimationController _later = AnimationController.unbounded(vsync: this, value: widget.data.laterHeight);
  late final AnimationController _assembled = AnimationController.unbounded(vsync: this, value: widget.assemble ? 0 : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assembled.value < 1 && !_assembled.isAnimating) {
      _springTo(_assembled, 1, HisaabMotion.calm);
    }
  }

  @override
  void didUpdateWidget(DayBlocks oldWidget) {
    super.didUpdateWidget(oldWidget);
    _springTo(_fill, widget.data.todayFill, HisaabMotion.standard);
    _springTo(_later, widget.data.laterHeight, HisaabMotion.standard);
  }

  void _springTo(AnimationController controller, double target, SpringDescription spring) {
    if (HisaabMotion.reduceMotion(context)) {
      controller.value = target;
      return;
    }
    if (controller.value != target) {
      controller.animateWith(SpringSimulation(spring, controller.value, target, controller.velocity));
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _later.dispose();
    _assembled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextPainter moreLabel = TextPainter(
      text: TextSpan(
        text: AppLocalizations.of(context).moreDays(widget.data.count),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.colors.displayInk2),
      ),
      textDirection: Directionality.of(context),
    )..layout();
    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_fill, _later, _assembled]),
          builder: (BuildContext context, Widget? _) => CustomPaint(
            size: Size.fromHeight(widget.height),
            painter: DayBlocksPainter(
              data: DayBlocksData(
                count: widget.data.count,
                style: widget.data.style,
                todayFill: _fill.value,
                laterHeight: _later.value,
              ),
              colors: DayBlocksColors(
                signal: context.colors.signal,
                idle: context.colors.blockIdle,
                outline: context.colors.displayInk2,
                edge: context.colors.displayEdge,
              ),
              moreLabel: moreLabel,
              assembled: _assembled.value.clamp(0, 1),
            ),
          ),
        ),
      ),
    );
  }
}
