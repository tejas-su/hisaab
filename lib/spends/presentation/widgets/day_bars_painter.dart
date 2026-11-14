import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// What the day bars show, in paise (SPEC FR-SP-7 AC-4, D194).
typedef DayBarsData = ({List<int> perDay, int? share, Set<int> marked});

/// Paints a cycle's *Everyday* spending as one bar per day, left to right: past the dotted [share]
/// line a bar is `ink`, under it `ink2`; a day with nothing spent is a dot on the axis, and each
/// [marked] day (the weekday line's) gets a dot under the axis.
class DayBarsPainter extends CustomPainter {
  const DayBarsPainter({required this.data, required this.ink, required this.ink2, required this.axis});

  final DayBarsData data;
  final Color ink;
  final Color ink2;
  final Color axis;

  /// Room under the axis for the marked-day dots.
  static const double markRoom = 8;
  static const double _barGap = 3;
  static const double _topRadius = 2;
  static const double _dotRadius = 1.5;
  static const double _dash = 2;
  static const double _dashGap = 4;
  static const double _shareStroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final double base = size.height - markRoom;
    final int top = math.max(data.perDay.fold(0, math.max), data.share ?? 0);
    final double slot = size.width / data.perDay.length;
    double heightOf(int amount) => top == 0 ? 0 : base * amount / top;
    for (final (int day, int amount) in data.perDay.indexed) {
      _day(canvas, Offset(slot * day, base), slot, amount == 0 ? null : heightOf(amount), _isOver(amount));
      if (data.marked.contains(day)) {
        canvas.drawCircle(Offset(slot * day + slot / 2, base + markRoom / 2 + 1), _dotRadius, Paint()..color = ink2);
      }
    }
    canvas.drawLine(Offset(0, base), Offset(size.width, base), Paint()..color = axis..strokeWidth = 1);
    final int? share = data.share;
    if (share != null) {
      _dotted(canvas, base - heightOf(share), size.width);
    }
  }

  bool _isOver(int amount) => data.share != null && amount > (data.share ?? 0);

  void _day(Canvas canvas, Offset foot, double slot, double? height, bool over) {
    if (height == null) {
      canvas.drawCircle(Offset(foot.dx + slot / 2, foot.dy - _dotRadius - 1), _dotRadius, Paint()..color = ink2);
      return;
    }
    final double width = math.max(1, slot - _barGap);
    final Rect bar = Rect.fromLTWH(foot.dx + (slot - width) / 2, foot.dy - height, width, height);
    canvas.drawRRect(
      RRect.fromRectAndCorners(bar, topLeft: const Radius.circular(_topRadius), topRight: const Radius.circular(_topRadius)),
      Paint()..color = over ? ink : ink2,
    );
  }

  void _dotted(Canvas canvas, double y, double width) {
    final Paint paint = Paint()
      ..color = ink2
      ..strokeWidth = _shareStroke
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < width; x += _dash + _dashGap) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + _dash, width), y), paint);
    }
  }

  @override
  bool shouldRepaint(DayBarsPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.ink != ink || oldDelegate.ink2 != ink2 || oldDelegate.axis != axis;
}
