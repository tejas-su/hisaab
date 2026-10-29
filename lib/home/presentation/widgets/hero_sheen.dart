import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// One diagonal pass of light across the hero card, like a card catching the light (D106).
///
/// It plays once when it first appears, after today's block starts filling in; give it a new
/// key (the hero uses today's date) to play it again on a new day. It never loops, and with
/// reduced motion it never plays. The band ignores touches and is not announced.
class HeroSheen extends StatefulWidget {
  const HeroSheen({super.key, required this.child});

  /// Finds the band while it is crossing, for tests.
  static const Key bandKey = ValueKey<String>('hero-sheen-band');

  final Widget child;

  @override
  State<HeroSheen> createState() => _HeroSheenState();
}

class _HeroSheenState extends State<HeroSheen> with SingleTickerProviderStateMixin {
  late final AnimationController _pass = AnimationController(vsync: this, duration: HisaabMotion.sheen);

  // why: the first quarter waits, so the light arrives after today's block has begun to fill.
  late final Animation<double> _progress = CurvedAnimation(
    parent: _pass,
    curve: const Interval(0.25, 1, curve: HisaabMotion.sweep),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pass.status == AnimationStatus.dismissed && !HisaabMotion.reduceMotion(context)) {
      _pass.forward();
    }
  }

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          // why: the band repaints every frame of the pass; its own layer keeps the card under it
          // (shadow blur, text, clip) from repainting with it.
          child: RepaintBoundary(
            child: AnimatedBuilder(animation: _pass, builder: (BuildContext context, Widget? _) => _band(context)),
          ),
        ),
      ),
    ],
  );

  Widget _band(BuildContext context) {
    if (!_pass.isAnimating) {
      return const SizedBox.shrink();
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: HisaabShapes.squircle(HisaabRadii.card), textDirection: Directionality.of(context)),
      child: CustomPaint(
        key: HeroSheen.bandKey,
        painter: HeroSheenPainter(progress: _progress.value, color: context.colors.displaySheen),
      ),
    );
  }
}

/// Paints the sheen: a soft diagonal band of [color] that slides from wholly off the top start
/// corner ([progress] 0) to wholly off the bottom end corner (1), so it never appears, sticks or
/// vanishes at an edge.
class HeroSheenPainter extends CustomPainter {
  const HeroSheenPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  // why: the band runs a little downhill, like light across a tilted card.
  static const double _slope = 0.4;

  // why: the band is about a sixth of the card's diagonal wide: a gleam, not a wash.
  static const double _bandFraction = 0.16;

  /// The unit direction the band travels across a card of [size].
  static Offset direction(Size size) {
    final Offset travel = Offset(size.width, size.height * _slope);
    return travel / travel.distance;
  }

  /// The band's trailing and leading edges at [progress], in the card's own coordinates.
  static (Offset, Offset) bandEnds(Size size, double progress) {
    final Offset along = direction(size);
    final double width = _bandFraction * Offset(size.width, size.height * _slope).distance;
    final double farCorner = size.width * along.dx + size.height * along.dy;
    final double centre = -width / 2 + progress * (farCorner + width);
    return (along * (centre - width / 2), along * (centre + width / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (Offset from, Offset to) = bandEnds(size, progress);
    final Color clear = color.withValues(alpha: 0);
    final Paint band = Paint()..shader = ui.Gradient.linear(from, to, <Color>[clear, color, clear], <double>[0, 0.5, 1]);
    canvas.drawRect(Offset.zero & size, band);
  }

  @override
  bool shouldRepaint(HeroSheenPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
