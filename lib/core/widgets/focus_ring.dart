import 'package:flutter/widgets.dart';

import '../design/hisaab_colors.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';

/// Draws the keyboard and D-pad focus ring around [child] while anything inside it has focus
/// (UI_DESIGN §9, principle 24, D99).
///
/// The ring is a [width] band of [HisaabColors.focus] outside a [gap] band of
/// [HisaabColors.focusGap], following a squircle of [radius], the control's own corner. It shows
/// only in [FocusHighlightMode.traditional] (keyboard, D-pad, switch access), never after a touch,
/// and it shows and hides at once. It is painted over the child and outside its bounds, so it
/// changes neither layout nor the tap target. It is focus only: a selected control keeps its look.
///
/// [Pressable] puts one on every app control; wrap a Material control (an [InkWell] row) in one
/// directly. A control inside a clipping card passes an [inset] of [outset] so the ring is drawn
/// inside its own bounds; a control whose visible well is smaller than its tap target passes the
/// difference, so the ring hugs the well.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.child, this.radius = HisaabRadii.chip, this.inset = EdgeInsets.zero});

  /// The ring's band width.
  static const double width = 2;

  /// The band between the control and the ring.
  static const double gap = 2;

  /// How far the ring reaches past the control's edge.
  static const double outset = width + gap;

  /// The control's corner radius; the ring's corners stay concentric with it.
  final double radius;

  /// Moves the edge the ring follows in from [child]'s bounds.
  final EdgeInsetsGeometry inset;

  final Widget child;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;
  bool _traditional = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) =>
      setState(() => _traditional = mode == FocusHighlightMode.traditional);

  @override
  Widget build(BuildContext context) => Focus(
        // why: only listens; the control inside owns focus, traversal and semantics.
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (bool focused) => setState(() => _focused = focused),
        child: CustomPaint(
          foregroundPainter: _focused && _traditional
              ? _FocusRingPainter(
                  colors: context.colors,
                  radius: widget.radius,
                  inset: widget.inset.resolve(Directionality.of(context)),
                )
              : null,
          child: widget.child,
        ),
      );
}

/// Paints the [HisaabColors.focusGap] band, then the [HisaabColors.focus] band outside it.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.colors, required this.radius, required this.inset});

  final HisaabColors colors;
  final double radius;
  final EdgeInsets inset;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect edge = inset.deflateRect(Offset.zero & size);
    _band(canvas, edge, FocusRing.gap / 2, FocusRing.gap, colors.focusGap);
    _band(canvas, edge, FocusRing.gap + FocusRing.width / 2, FocusRing.width, colors.focus);
  }

  // why: a stroke centred [offset] outside [edge] with its radius grown by the same amount keeps
  // the band concentric with the control's squircle.
  void _band(Canvas canvas, Rect edge, double offset, double strokeWidth, Color color) {
    final Path path = HisaabShapes.squircle(radius + offset).getOuterPath(edge.inflate(offset));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.radius != radius || oldDelegate.inset != inset;
}
