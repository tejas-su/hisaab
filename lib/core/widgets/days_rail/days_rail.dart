import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

import '../../design/app_icon.dart';
import '../../design/app_icons.dart';
import '../../design/hisaab_dimensions.dart';
import '../../design/hisaab_motion.dart';
import '../../design/hisaab_type.dart';
import '../../extensions/build_context_extensions.dart';
import 'days_rail_data.dart';
import 'days_rail_painter.dart';

/// The days left until payday as a rail of dots, today's first, ending at the payday flag, with
/// [todayCaption] and [laterCaption] under it (SPEC BR-6). It sits under the hero's chart in
/// both modes.
///
/// [assemble] brings the dots in one after another on `calm`, once, after onboarding. The hero
/// reads the whole card as one sentence, so the rail carries no semantics of its own.
class DaysRail extends StatefulWidget {
  const DaysRail({
    super.key,
    required this.data,
    required this.todayCaption,
    required this.laterCaption,
    required this.payday,
    this.assemble = false,
  });

  final DaysRailData data;
  final String todayCaption;
  final String laterCaption;

  /// The payday flag's date, e.g. "7 Nov".
  final String payday;
  final bool assemble;

  /// Space between the dots and the flag.
  static const double flagGap = 10;
  static const double _flagIconSize = 16;
  static const double _captionGap = 4;

  @override
  State<DaysRail> createState() => _DaysRailState();
}

class _DaysRailState extends State<DaysRail> with SingleTickerProviderStateMixin {
  late final AnimationController _arrived = AnimationController.unbounded(vsync: this, value: widget.assemble ? 0 : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrived.value == 1 || _arrived.isAnimating) {
      return;
    }
    if (HisaabMotion.reduceMotion(context)) {
      _arrived.value = 1;
      return;
    }
    _arrived.animateWith(SpringSimulation(HisaabMotion.calm, 0, 1, 0)).whenCompleteOrCancel(_rest);
  }

  void _rest() {
    if (mounted) {
      _arrived.value = 1;
    }
  }

  @override
  void dispose() {
    _arrived.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? caption = HisaabType.regular(Theme.of(context).textTheme.labelSmall)?.copyWith(color: context.colors.displayInk2);
    final TextStyle? flagStyle = HisaabType.emphasized(caption)?.copyWith(color: context.colors.displayInk);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double line = scaler.scale(flagStyle?.fontSize ?? 0) * (flagStyle?.height ?? 1);
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                SizedBox(height: line, width: double.infinity, child: _dots(context)),
                const SizedBox(height: DaysRail._captionGap),
                Row(
                  children: <Widget>[
                    Text(widget.todayCaption, style: caption),
                    const SizedBox(width: HisaabSpacing.s),
                    // why: ends under the last dot, past which sits the flag.
                    Expanded(child: Text(widget.laterCaption, style: caption, textAlign: TextAlign.end)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: DaysRail.flagGap),
          AppIcon(AppIcons.payday, size: DaysRail._flagIconSize, color: context.colors.displayInk),
          const SizedBox(width: HisaabSpacing.xs),
          Text(widget.payday, style: flagStyle),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _arrived,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            painter: DaysRailPainter(
              data: widget.data,
              arrived: _arrived.value.clamp(0, 1),
              colors: DaysRailColors(
                signal: context.colors.signal,
                idle: context.colors.blockIdle,
                edge: context.colors.displayEdge,
                ink2: context.colors.displayInk2,
                card: context.colors.display,
              ),
            ),
          ),
        ),
      );
}
