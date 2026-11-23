import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import 'story_motif.dart';

/// Paints one [StoryMotif] in 1dp strokes of [color]. It reaches past the edges where the motif's
/// drift would otherwise uncover a bare edge; the page clips it.
class StoryArtPainter extends CustomPainter {
  const StoryArtPainter({required this.motif, required this.color, required this.textDirection});

  final StoryMotif motif;
  final Color color;

  /// Anchors on the end side sit on the right in left-to-right and on the left in right-to-left.
  final TextDirection textDirection;

  static const double _stroke = 1;

  // why: a fixed seed keeps the blocks identical on every paint, so nothing jumps between pages.
  static const int _blocksSeed = 23;

  /// The x that sits [fraction] of [size]'s width in from the end edge.
  static double endX(Size size, double fraction, TextDirection direction) =>
      direction == TextDirection.rtl ? size.width * fraction : size.width * (1 - fraction);

  /// The x that sits [fraction] of [size]'s width in from the start edge.
  static double startX(Size size, double fraction, TextDirection direction) => endX(size, 1 - fraction, direction);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..isAntiAlias = true;
    switch (motif) {
      case StoryMotif.rosette:
        canvas.drawPath(_rosette(size), line);
      case StoryMotif.rings:
        _rings(canvas, size, line);
      case StoryMotif.rays:
        _rays(canvas, size, line);
      case StoryMotif.waves:
        _waves(canvas, size, line);
      case StoryMotif.orbits:
        _orbits(canvas, size, line);
      case StoryMotif.blocks:
        _blocks(canvas, size, line);
    }
  }

  // why: rings of a circle rippled by two sine waves, the banknote line work of the hero etch.
  Path _rosette(Size size) {
    const int rings = 16;
    const int steps = 240;
    final double reach = size.shortestSide * 0.55;
    final Offset centre = Offset(endX(size, 0.12, textDirection), math.min(size.height * 0.3, reach));
    final Path path = Path();
    for (int ring = 0; ring < rings; ring++) {
      final double base = reach * (0.3 + 0.7 * ring / rings);
      path.addPolygon(
        List<Offset>.generate(steps, (int i) {
          final double t = i / steps * 2 * math.pi;
          final double radius = base + reach * (0.05 * math.sin(18 * t + ring * 0.35) + 0.025 * math.sin(5 * t));
          return centre + Offset(radius * math.cos(t), radius * math.sin(t));
        }),
        true,
      );
    }
    return path;
  }

  void _rings(Canvas canvas, Size size, Paint line) {
    final Offset centre = Offset(endX(size, 0, textDirection), size.height * 0.92);
    for (double radius = HisaabSpacing.l; radius < size.longestSide; radius += HisaabSpacing.l) {
      canvas.drawCircle(centre, radius, line);
    }
  }

  void _rays(Canvas canvas, Size size, Paint line) {
    const int rays = 36;
    final bool rtl = textDirection == TextDirection.rtl;
    final Offset origin = Offset(startX(size, 0, textDirection), size.height);
    final double reach = size.longestSide * 1.5;
    final double first = rtl ? math.pi : 0;
    final double sweep = rtl ? math.pi / 2 : -math.pi / 2;
    for (int ray = 0; ray <= rays; ray++) {
      final double angle = first + sweep * ray / rays;
      canvas.drawLine(origin, origin + Offset(math.cos(angle), math.sin(angle)) * reach, line);
    }
    for (double radius = HisaabSpacing.xxxl * 2; radius < reach; radius += HisaabSpacing.xxxl * 2) {
      canvas.drawArc(Rect.fromCircle(center: origin, radius: radius), first, sweep, false, line);
    }
  }

  void _waves(Canvas canvas, Size size, Paint line) {
    const int count = 14;
    const int steps = 96;
    final double top = size.height * 0.5;
    final double gap = (size.height - top) / count;
    final double wavelength = math.max(size.width / 2.5, 1);
    final double start = math.min(0, StoryMotif.waves.shift.dx);
    final double span = size.width + StoryMotif.waves.shift.dx.abs();
    for (int wave = 0; wave < count; wave++) {
      final double baseline = top + gap * (wave + 0.5);
      final double amplitude = gap * (0.6 + 0.08 * wave);
      canvas.drawPoints(
        ui.PointMode.polygon,
        List<Offset>.generate(steps + 1, (int i) {
          final double x = start + span * i / steps;
          return Offset(x, baseline + amplitude * math.sin(2 * math.pi * x / wavelength + wave * 0.6));
        }),
        line,
      );
    }
  }

  void _orbits(Canvas canvas, Size size, Paint line) {
    final double radius = size.shortestSide * 0.42;
    final double y = size.height - radius * 0.9;
    for (final Offset centre in <Offset>[Offset(startX(size, 0.3, textDirection), y), Offset(endX(size, 0.3, textDirection), y)]) {
      for (double ring = HisaabSpacing.m; ring <= radius; ring += HisaabSpacing.m) {
        canvas.drawCircle(centre, ring, line);
      }
    }
  }

  // why: the app's own mark, the day block, tossed like confetti for the end of the month; it
  // starts above the page so the downward drift never uncovers an empty band at the top.
  void _blocks(Canvas canvas, Size size, Paint line) {
    final math.Random random = math.Random(_blocksSeed);
    final int count = (size.width * size.height / 9000).clamp(12, 80).floor();
    final Paint fill = Paint()..color = color;
    for (int i = 0; i < count; i++) {
      final double side = HisaabSpacing.m + random.nextDouble() * HisaabSpacing.xxl;
      final Offset centre = Offset(random.nextDouble() * size.width, size.height * (0.4 + 0.6 * random.nextDouble()) - StoryMotif.blocks.shift.dy);
      final Rect shape = Rect.fromCenter(center: Offset.zero, width: side, height: side * 1.4);
      canvas
        ..save()
        ..translate(centre.dx, centre.dy)
        ..rotate((random.nextDouble() - 0.5) * math.pi / 2)
        ..drawRRect(RRect.fromRectAndRadius(shape, const Radius.circular(HisaabRadii.block / 2)), i % 3 == 0 ? fill : line)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(StoryArtPainter oldDelegate) =>
      oldDelegate.motif != motif || oldDelegate.color != color || oldDelegate.textDirection != textDirection;
}
