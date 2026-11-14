import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// One cycle's bar in the months strip, in paise, against the strip's shared [scale] (SPEC FR-SP-8).
typedef MonthBarData = ({int spent, int saved, int income, int scale, bool running});

/// The colours a month bar is painted with, from the theme's tokens.
typedef MonthBarColours = ({Color ink, Color ink2, Color surface});

/// Paints one cycle of the months strip: *Spent* solid `ink` (a dashed outline while the cycle
/// runs), *Saved* an outlined cap with a [minCap] floor, a dotted line at its money in, and the part
/// past that line striped. [vertical] false lays the bar along the row for large text.
class MonthBarPainter extends CustomPainter {
  const MonthBarPainter({required this.data, required this.colours, this.vertical = true});

  final MonthBarData data;
  final MonthBarColours colours;
  final bool vertical;

  static const double minCap = 5;
  static const double barThickness = 24;
  static const double _outline = 2;
  static const double _dash = 4;
  static const double _gap = 3;
  static const double _hatchStep = 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.scale <= 0) {
      return;
    }
    final double length = vertical ? size.height : size.width;
    double at(int amount) => length * amount / data.scale;
    final double spentEnd = at(data.spent);
    final double savedEnd = data.saved > 0 ? spentEnd + math.max(minCap, at(data.saved)) : spentEnd;
    _spent(canvas, _span(size, 0, spentEnd));
    if (data.saved > 0) {
      _outlined(canvas, _span(size, spentEnd, savedEnd));
    }
    if (data.income > 0) {
      final double line = at(data.income);
      if (savedEnd > line) {
        _hatch(canvas, _span(size, line, savedEnd));
      }
      _dotted(canvas, size, line);
    }
  }

  /// The bar's rectangle from [from] to [to] along its length, centred across.
  Rect _span(Size size, double from, double to) {
    if (vertical) {
      final double left = (size.width - barThickness) / 2;
      return Rect.fromLTRB(left, size.height - to, left + barThickness, size.height - from);
    }
    final double top = (size.height - barThickness) / 2;
    return Rect.fromLTRB(from, top, to, top + barThickness);
  }

  void _spent(Canvas canvas, Rect rect) {
    if (rect.isEmpty) {
      return;
    }
    if (!data.running) {
      canvas.drawRect(rect, Paint()..color = colours.ink);
      return;
    }
    _dashedRect(canvas, rect.deflate(_outline / 2));
  }

  void _outlined(Canvas canvas, Rect rect) {
    final Rect inner = rect.deflate(_outline / 2);
    canvas
      ..drawRect(inner, Paint()..color = colours.surface)
      ..drawRect(inner, Paint()..style = PaintingStyle.stroke..strokeWidth = _outline..color = colours.ink);
  }

  void _hatch(Canvas canvas, Rect rect) {
    final Paint stripe = Paint()..color = colours.ink..strokeWidth = _hatchStep / 2;
    canvas
      ..save()
      ..clipRect(rect)
      ..drawRect(rect, Paint()..color = colours.surface);
    for (double x = rect.left - rect.height; x < rect.right; x += _hatchStep) {
      canvas.drawLine(Offset(x, rect.bottom), Offset(x + rect.height, rect.top), stripe);
    }
    canvas.restore();
  }

  void _dotted(Canvas canvas, Size size, double at) {
    final Paint paint = Paint()
      ..color = colours.ink2
      ..strokeWidth = _outline
      ..strokeCap = StrokeCap.round;
    final double span = vertical ? size.width : size.height;
    for (double d = 0; d < span; d += _gap + _outline) {
      final double end = math.min(d + _outline / 2, span);
      vertical
          ? canvas.drawLine(Offset(d, size.height - at), Offset(end, size.height - at), paint)
          : canvas.drawLine(Offset(at, d), Offset(at, end), paint);
    }
  }

  void _dashedRect(Canvas canvas, Rect rect) {
    final Paint paint = Paint()
      ..color = colours.ink
      ..strokeWidth = _outline;
    for (final (Offset from, Offset to) in <(Offset, Offset)>[
      (rect.topLeft, rect.topRight),
      (rect.topRight, rect.bottomRight),
      (rect.bottomRight, rect.bottomLeft),
      (rect.bottomLeft, rect.topLeft),
    ]) {
      _dashedLine(canvas, from, to, paint);
    }
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final double length = (to - from).distance;
    if (length == 0) {
      return;
    }
    final Offset step = (to - from) / length;
    for (double d = 0; d < length; d += _dash + _gap) {
      canvas.drawLine(from + step * d, from + step * math.min(d + _dash, length), paint);
    }
  }

  @override
  bool shouldRepaint(MonthBarPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.colours != colours || oldDelegate.vertical != vertical;
}
