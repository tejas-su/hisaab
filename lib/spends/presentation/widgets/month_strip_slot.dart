import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../domain/entities/cycle_bar.dart';
import 'month_bar_painter.dart';

/// One cycle in the months strip (SPEC FR-SP-8): a 48dp-wide button holding its bar and its label,
/// the label an `ink` pill when [picked] (the picked-chip look), and the marigold dot under a
/// running cycle. [horizontal] lays it out as a row for large text. TalkBack reads [spoken].
class MonthStripSlot extends StatelessWidget {
  const MonthStripSlot({
    super.key,
    required this.bar,
    required this.scale,
    required this.label,
    required this.spoken,
    required this.picked,
    required this.onPressed,
    this.horizontal = false,
  });

  final CycleBar bar;

  /// The strip's shared top, in paise.
  final int scale;
  final String label;
  final String spoken;
  final bool picked;
  final VoidCallback onPressed;
  final bool horizontal;

  static const double barHeight = 120;
  static const double _dot = 8;
  static const double _labelWidth = 64;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: spoken,
        selected: picked,
        onPressed: onPressed,
        builder: (BuildContext context, bool pressed) => ConstrainedBox(
          constraints: const BoxConstraints(minWidth: HisaabSizes.minTouchTarget, minHeight: HisaabSizes.minTouchTarget),
          child: horizontal ? _row(context) : _column(context),
        ),
      );

  Widget _column(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: barHeight, width: double.infinity, child: _painted(context, vertical: true)),
          const SizedBox(height: HisaabSpacing.xs),
          _label(context),
          SizedBox(height: _dot + HisaabSpacing.xs, child: bar.isRunning ? Center(child: _todayDot(context)) : null),
        ],
      );

  Widget _row(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.xs),
        child: Row(
          children: <Widget>[
            SizedBox(width: _labelWidth, child: Align(alignment: AlignmentDirectional.centerStart, child: _label(context))),
            Expanded(child: SizedBox(height: HisaabSizes.minTouchTarget, child: _painted(context, vertical: false))),
            if (bar.isRunning) ...<Widget>[const SizedBox(width: HisaabSpacing.s), _todayDot(context)],
          ],
        ),
      );

  Widget _painted(BuildContext context, {required bool vertical}) => CustomPaint(
        painter: MonthBarPainter(
          vertical: vertical,
          data: (spent: bar.spent.amountMinor, saved: bar.saved.amountMinor, income: bar.income.amountMinor, scale: scale, running: bar.isRunning),
          colours: (ink: context.colors.ink, ink2: context.colors.ink2, surface: context.colors.surface),
        ),
      );

  Widget _label(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelSmall;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.s, vertical: 2),
      decoration: picked ? ShapeDecoration(color: context.colors.ink, shape: HisaabShapes.squircle(HisaabRadii.chip)) : null,
      child: Text(label, style: picked ? style?.copyWith(color: context.colors.background) : style),
    );
  }

  // why: the pace chart's today mark: marigold never sits bare on the light card, so it has an ink ring.
  Widget _todayDot(BuildContext context) => Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(color: context.colors.signal, shape: BoxShape.circle, border: Border.all(color: context.colors.ink, width: 1.5)),
      );
}
