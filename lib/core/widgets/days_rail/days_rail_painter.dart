import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';

import 'days_rail_data.dart';
import 'days_rail_layout.dart';

/// The colours [DaysRailPainter] uses, taken from the hero's display tokens.
final class DaysRailColors extends Equatable {
  const DaysRailColors({required this.signal, required this.idle, required this.edge, required this.ink2, required this.card});

  /// Today's dot (`signal`).
  final Color signal;

  /// Later days' dots (`blockIdle`).
  final Color idle;

  /// Edge round today's marigold (`displayEdge`); transparent draws none.
  final Color edge;

  /// The hatch and outlines (`displayInk2`).
  final Color ink2;

  /// The card colour behind the hatch (`display`).
  final Color card;

  @override
  List<Object?> get props => <Object?>[signal, idle, edge, ink2, card];
}

/// Paints one dot per day left, today's first and bigger, in its state's shape (SPEC BR-5, BR-6).
///
/// [arrived] runs 0→1 as the dots arrive from the start edge, one after another.
class DaysRailPainter extends CustomPainter {
  const DaysRailPainter({required this.data, required this.colors, this.arrived = 1});

  final DaysRailData data;
  final DaysRailColors colors;
  final double arrived;

  static const double edgeWidth = 1.5;
  static const double _ringWidth = 2;
  static const double _outlineWidth = 1.2;
  static const double _hatchSpacing = 3.5;

  /// How many dots are still arriving at once while [arrived] runs.
  static const double _arrivalSpread = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final List<RailDot> dots = DaysRailLayout.dots(count: data.count, width: size.width);
    for (int i = 0; i < dots.length; i++) {
      final double scale = (arrived * (dots.length + _arrivalSpread) - i).clamp(0, 1).toDouble();
      final Offset centre = Offset(dots[i].centre, size.height / 2);
      final double radius = dots[i].size / 2 * scale;
      if (radius > 0) {
        i == 0 ? _today(canvas, centre, radius) : _later(canvas, centre, radius);
      }
    }
  }

  void _today(Canvas canvas, Offset centre, double radius) {
    switch (data.style) {
      case DaysRailStyle.onTrack:
        canvas.drawCircle(centre, radius, Paint()..color = colors.signal);
        _edge(canvas, centre, radius);
      case DaysRailStyle.slowDown:
        canvas
          ..drawCircle(centre, radius, Paint()..color = colors.idle)
          ..drawCircle(centre, radius - _ringWidth / 2, _stroke(colors.signal, _ringWidth));
        _edge(canvas, centre, radius);
      case DaysRailStyle.overToday || DaysRailStyle.overCycle:
        _hatched(canvas, centre, radius);
    }
  }

  void _later(Canvas canvas, Offset centre, double radius) {
    if (data.style == DaysRailStyle.overCycle) {
      canvas.drawCircle(centre, radius - _outlineWidth / 2, _stroke(colors.ink2, _outlineWidth));
      return;
    }
    canvas.drawCircle(centre, radius, Paint()..color = colors.idle);
  }

  void _hatched(Canvas canvas, Offset centre, double radius) {
    final Rect area = Rect.fromCircle(center: centre, radius: radius);
    final Paint line = Paint()
      ..color = colors.ink2
      ..strokeWidth = _outlineWidth;
    canvas
      ..save()
      ..clipPath(Path()..addOval(area))
      ..drawCircle(centre, radius, Paint()..color = colors.card);
    for (double x = area.left - area.height; x < area.right; x += _hatchSpacing) {
      canvas.drawLine(Offset(x, area.bottom), Offset(x + area.height, area.top), line);
    }
    canvas
      ..restore()
      ..drawCircle(centre, radius - edgeWidth / 2, _stroke(colors.ink2, edgeWidth));
  }

  void _edge(Canvas canvas, Offset centre, double radius) {
    if (colors.edge.a > 0) {
      canvas.drawCircle(centre, radius - edgeWidth / 2, _stroke(colors.edge, edgeWidth));
    }
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  @override
  bool shouldRepaint(DaysRailPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.colors != colors || oldDelegate.arrived != arrived;
}
