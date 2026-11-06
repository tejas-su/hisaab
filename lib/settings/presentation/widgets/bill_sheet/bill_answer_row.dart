import 'package:flutter/material.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_motion.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/pressable.dart';

/// One answer on the bill: its [label], a dotted leader, its [value] and a chevron; a tap
/// opens its question (SPEC FR-SE-1 AC-2, AC-3). Read as [semanticLabel].
///
/// When [flashed], it flashes `sunk` once, after its answer was saved.
class BillAnswerRow extends StatelessWidget {
  const BillAnswerRow({
    super.key,
    required this.label,
    required this.value,
    required this.semanticLabel,
    required this.onPressed,
    this.leading,
    this.flashed = false,
  });

  final String label;
  final String value;
  final String semanticLabel;
  /// Opens the answer's question; null shows the answer read-only, with no arrow.
  final VoidCallback? onPressed;

  /// A glyph before [value], for the icon row.
  final AppIconData? leading;
  final bool flashed;

  static const double _minHeight = 56;
  static const Duration _flash = Duration(milliseconds: 1400);
  static const double _maxValueWidth = 160;
  static const double _labelShare = 0.45;
  static const double _valueShare = 0.38;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: semanticLabel,
        onPressed: onPressed,
        builder: (BuildContext context, bool pressed) => TweenAnimationBuilder<double>(
          key: ValueKey<bool>(flashed),
          tween: Tween<double>(begin: flashed ? 1 : 0, end: 0),
          duration: HisaabMotion.reduceMotion(context) ? HisaabMotion.reducedCrossfade : _flash,
          builder: (BuildContext context, double flash, Widget? child) => Container(
            constraints: const BoxConstraints(minHeight: _minHeight),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.s),
            decoration: BoxDecoration(
              color: pressed ? context.colors.sunk : Color.lerp(context.colors.display, context.colors.sunk, flash),
              borderRadius: BorderRadius.circular(HisaabRadii.chip),
            ),
            child: child,
          ),
          child: _content(context),
        ),
      );

  // why: fixed shares of the row, not text widths, so at large text the label wraps and the
  // value stays on the end edge while the leader takes what is left.
  Widget _content(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final TextTheme text = Theme.of(context).textTheme;
          final AppIconData? glyph = leading;
          final double valueWidth = (constraints.maxWidth * _valueShare).clamp(0, _maxValueWidth);
          return Row(
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * _labelShare),
                child: Text(label, style: text.bodyLarge),
              ),
              const Expanded(child: _Leader()),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: valueWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (glyph != null) ...<Widget>[AppIcon(glyph, size: 18), const SizedBox(width: 6)],
                    // why: "Changes every month" is wider than the value column on a phone, so it may take a
                    // second line rather than be cut (D123).
                    Flexible(child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: text.titleMedium)),
                  ],
                ),
              ),
              if (onPressed != null) ...<Widget>[
                const SizedBox(width: 6),
                AppIcon(AppIcons.next, size: 18, color: context.colors.displayInk2),
              ],
            ],
          );
        },
      );
}

/// The dotted leader between an answer's label and its value.
class _Leader extends StatelessWidget {
  const _Leader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.xs),
        child: CustomPaint(size: const Size.fromHeight(2), painter: _DotsPainter(context.colors.hairline)),
      );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  static const double _step = 5;
  static const double _radius = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = color;
    for (double x = _radius; x < size.width; x += _step) {
      canvas.drawCircle(Offset(x, size.height / 2), _radius, dot);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => oldDelegate.color != color;
}
