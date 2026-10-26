import 'package:flutter/rendering.dart';

/// Paints a *Where it went* bar: an ink fill on a sunk track, and with a limit, a tick at the
/// limit and hatching past it, never red (SPEC BR-12, UI_DESIGN §3.3).
class LimitBarPainter extends CustomPainter {
  const LimitBarPainter({
    required this.fill,
    required this.limitAt,
    required this.ink,
    required this.track,
    required this.notch,
    required this.tick,
  });

  /// Filled share of the width, 0–1.
  final double fill;

  /// Where the limit sits as a share of the width, or null without a limit (or past the bar).
  final double? limitAt;
  final Color ink;
  final Color track;

  /// The gap cut into the bar at the limit (the card's colour).
  final Color notch;

  /// The tick marks above and below the bar at the limit.
  final Color tick;

  static const double _barHeight = 8;
  static const double _hatchSpacing = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final double top = (size.height - _barHeight) / 2;
    final Rect bar = Rect.fromLTWH(0, top, size.width, _barHeight);
    final RRect shape = RRect.fromRectAndRadius(bar, const Radius.circular(_barHeight / 2));
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(bar, Paint()..color = track);
    final double? limit = limitAt;
    final double solidEnd = limit != null && fill > limit ? limit : fill;
    canvas.drawRect(Rect.fromLTRB(0, top, size.width * solidEnd, bar.bottom), Paint()..color = ink);
    if (limit != null && fill > limit) {
      _hatch(canvas, Rect.fromLTRB(size.width * limit, top, size.width * fill, bar.bottom));
    }
    canvas.restore();
    if (limit != null) {
      final double x = size.width * limit;
      canvas
        ..drawRect(Rect.fromLTWH(x - 1, top, 2, _barHeight), Paint()..color = notch)
        ..drawRect(Rect.fromLTWH(x - 1, 0, 2, top), Paint()..color = tick)
        ..drawRect(Rect.fromLTWH(x - 1, bar.bottom, 2, top), Paint()..color = tick);
    }
  }

  void _hatch(Canvas canvas, Rect area) {
    final Paint line = Paint()
      ..color = ink
      ..strokeWidth = 2;
    canvas
      ..save()
      ..clipRect(area);
    for (double x = area.left - area.height; x < area.right; x += _hatchSpacing) {
      canvas.drawLine(Offset(x, area.bottom), Offset(x + area.height, area.top), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LimitBarPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.limitAt != limitAt ||
      oldDelegate.ink != ink ||
      oldDelegate.track != track ||
      oldDelegate.notch != notch ||
      oldDelegate.tick != tick;
}
