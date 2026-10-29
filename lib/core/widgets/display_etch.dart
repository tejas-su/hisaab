import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';

/// The hero's finish: a guilloché rosette near the top end corner, like the line work on a
/// payment card or a rupee note, over a faint grain, inside a solid and a dashed keyline like the
/// frame printed round a rupee note (D106, D107, case study 10).
///
/// Decoration only: it fills its parent, draws the rosette, grain and solid keyline in
/// `displayEtch` and the dashed keyline in `hairline`, is never announced, and paints once
/// behind a [RepaintBoundary].
class DisplayEtch extends StatelessWidget {
  const DisplayEtch({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: DisplayEtchPainter(
        color: context.colors.displayEtch,
        frame: context.colors.hairline,
        textDirection: Directionality.of(context),
      ),
    ),
  );
}

/// Paints [DisplayEtch]: the rosette's rings in hairline strokes, the grain as single dots, the
/// solid keyline, then the dashed keyline.
class DisplayEtchPainter extends CustomPainter {
  const DisplayEtchPainter({required this.color, required this.frame, required this.textDirection});

  /// The rosette, grain and solid keyline's colour.
  final Color color;

  /// The dashed keyline's colour.
  final Color frame;

  /// The rosette sits at the end corner: top right in left-to-right, top left in right-to-left.
  final TextDirection textDirection;

  static const double _rosetteInset = 80;
  static const double _rosetteTop = 60;
  static const double _stroke = 0.6;

  // why: one grain dot per this many square dp reads as texture, not as dust.
  static const double _grainArea = 60;

  // why: a fixed seed keeps the grain identical on every paint, so it never shimmers.
  static const int _grainSeed = 7;

  // why: like a rupee note's frame, a solid line 6dp in and a dashed one 10dp in, leaving 10dp clear
  // of the 20dp content inset; each radius shrinks by its inset, so the lines stay concentric.
  static const double _frameInset = 6;
  static const double _dashedInset = 10;
  static const double _dash = 4;
  static const double _dashGap = 3;

  static final Path _rosette = _buildRosette();

  /// The solid keyline's bounds on a card of [size].
  static Rect frameRect(Size size) => (Offset.zero & size).deflate(_frameInset);

  /// The solid keyline: the card's squircle, [_frameInset] in, one line.
  static Path framePath(Size size) => HisaabShapes.squircle(HisaabRadii.card - _frameInset).getOuterPath(frameRect(size));

  /// The dashed keyline's bounds on a card of [size].
  static Rect dashedFrameRect(Size size) => (Offset.zero & size).deflate(_dashedInset);

  /// The dashed keyline: the card's squircle, [_dashedInset] in, cut into 4dp dashes 3dp apart.
  static Path dashedFramePath(Size size) {
    final Path outline = HisaabShapes.squircle(HisaabRadii.card - _dashedInset).getOuterPath(dashedFrameRect(size));
    final Path dashes = Path();
    for (final ui.PathMetric metric in outline.computeMetrics()) {
      for (double start = 0; start < metric.length; start += _dash + _dashGap) {
        dashes.addPath(metric.extractPath(start, math.min(start + _dash, metric.length)), Offset.zero);
      }
    }
    return dashes;
  }

  /// Where the rosette's centre falls on a card of [size].
  static Offset rosetteCentre(Size size, TextDirection direction) =>
      Offset(direction == TextDirection.rtl ? _rosetteInset : size.width - _rosetteInset, _rosetteTop);

  // why: 14 rings of a circle rippled by two sine waves, the shape of banknote security printing.
  static Path _buildRosette() {
    const int rings = 14;
    const int steps = 720;
    final Path path = Path();
    for (int ring = 0; ring < rings; ring++) {
      final double base = 40 + ring * 7.5;
      final List<Offset> points = List<Offset>.generate(steps, (int i) {
        final double t = i / steps * 2 * math.pi;
        final double radius = base + 6 * math.sin(18 * t + ring * 0.35) + 3 * math.sin(5 * t);
        return Offset(radius * math.cos(t), radius * math.sin(t));
      });
      path.addPolygon(points, true);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..isAntiAlias = true;
    final Offset centre = rosetteCentre(size, textDirection);
    // why: translating the canvas draws the shared rosette without copying its points.
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..drawPath(_rosette, line)
      ..restore()
      ..drawRawPoints(ui.PointMode.points, _grain(size), line..strokeWidth = 1)
      ..drawPath(framePath(size), line)
      ..drawPath(dashedFramePath(size), line..color = frame);
  }

  static Float32List _grain(Size size) {
    final math.Random random = math.Random(_grainSeed);
    final int count = (size.width * size.height / _grainArea).floor();
    return Float32List.fromList(List<double>.generate(count * 2, (int i) => random.nextDouble() * (i.isEven ? size.width : size.height)));
  }

  @override
  bool shouldRepaint(DisplayEtchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.frame != frame || oldDelegate.textDirection != textDirection;
}
