import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';

import '../../design/hisaab_dimensions.dart';
import 'today_bar_data.dart';
import 'today_bar_layout.dart';

/// The colours [TodayBarPainter] uses, taken from the hero's display tokens.
final class TodayBarColors extends Equatable {
  const TodayBarColors({
    required this.signal,
    required this.idle,
    required this.edge,
    required this.ink,
    required this.ink2,
    required this.card,
  });

  /// The yellow (`signal`).
  final Color signal;

  /// Bites and the empty bar (`blockIdle`).
  final Color idle;

  /// The yellow's edge (`displayEdge`); transparent draws none.
  final Color edge;

  /// The share tick (`displayInk`).
  final Color ink;

  /// The hatch and the names (`displayInk2`).
  final Color ink2;

  /// The card colour cut round the tick and behind the hatch (`display`).
  final Color card;

  @override
  List<Object?> get props => <Object?>[signal, idle, edge, ink, ink2, card];
}

/// Paints today's bar: the yellow, the bites with their names under them, and, when overspent,
/// the share tick with a hatch past it (SPEC BR-6).
///
/// It moves from [from] to [to] as [progress] runs 0→1: the yellow and every bite re-span together
/// when today's share changes, and a bite that is new is uncovered by the yellow pulling back.
class TodayBarPainter extends CustomPainter {
  const TodayBarPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.colors,
    required this.names,
    this.textScaler = TextScaler.noScaling,
  });

  final TodayBarData from;
  final TodayBarData to;
  final double progress;
  final TodayBarColors colors;

  /// The names' style.
  final TextStyle? names;

  /// The user's text size, applied to the names.
  final TextScaler textScaler;

  static const double barHeight = 48;

  /// Space between the bar and the names under it.
  static const double nameGap = 4;
  static const double tickThickness = 2;
  static const double edgeWidth = 1.5;
  static const double _ringWidth = 3;
  static const double _tickOverhang = 4;
  static const double _hatchSpacing = 5;
  static const double _nameInset = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final TodayBarLayout end = TodayBarLayout.of(to, size.width);
    final TodayBarLayout now = TodayBarLayout.lerp(TodayBarLayout.of(from, size.width), end, progress);
    final double yellow = now.yellowEnd;
    if (end.bites.isEmpty && end.yellowEnd == 0) {
      _piece(canvas, 0, size.width, colors.idle);
    }
    _yellow(canvas, yellow);
    for (final BitePiece bite in now.bites) {
      _piece(canvas, math.max(bite.left, yellow + TodayBarLayout.gap), bite.left + bite.width, colors.idle);
    }
    final double? tick = end.tickX;
    if (tick != null) {
      _hatch(canvas, Rect.fromLTRB(tick, 0, size.width, barHeight));
      _tick(canvas, tick);
    }
    _names(canvas, end);
  }

  void _yellow(Canvas canvas, double right) {
    if (right <= 0) {
      return;
    }
    final RRect shape = _shape(0, right);
    if (to.style == TodayBarStyle.slowDown) {
      canvas
        ..drawRRect(shape, Paint()..color = colors.idle)
        ..drawRRect(shape.deflate(_ringWidth / 2), _stroke(colors.signal, _ringWidth));
    } else {
      canvas.drawRRect(shape, Paint()..color = colors.signal);
    }
    if (colors.edge.a > 0) {
      canvas.drawRRect(shape.deflate(edgeWidth / 2), _stroke(colors.edge, edgeWidth));
    }
  }

  void _piece(Canvas canvas, double left, double right, Color color) {
    if (right - left <= 0) {
      return;
    }
    canvas.drawRRect(_shape(left, right), Paint()..color = color);
  }

  void _hatch(Canvas canvas, Rect area) {
    final RRect shape = _shape(area.left, area.right);
    final Paint line = Paint()
      ..color = colors.ink2
      ..strokeWidth = edgeWidth;
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRRect(shape, Paint()..color = colors.card);
    for (double x = area.left - area.height; x < area.right; x += _hatchSpacing) {
      canvas.drawLine(Offset(x, area.bottom), Offset(x + area.height, area.top), line);
    }
    canvas
      ..drawRRect(shape.deflate(edgeWidth / 2), _stroke(colors.ink2, edgeWidth))
      ..restore();
  }

  void _tick(Canvas canvas, double x) {
    final Rect tick = Rect.fromLTRB(x - tickThickness / 2, -_tickOverhang, x + tickThickness / 2, barHeight + _tickOverhang);
    canvas
      ..drawRect(tick.inflate(1), Paint()..color = colors.card)
      ..drawRect(tick, Paint()..color = colors.ink);
  }

  // why: a name is drawn only under a bite wide enough for it, and never under the hatch, where
  // the bite is no longer within today's share.
  void _names(Canvas canvas, TodayBarLayout layout) {
    for (final BitePiece bite in layout.bites) {
      final String? label = bite.label;
      final double centre = bite.left + bite.width / 2;
      final double? tick = layout.tickX;
      if (label == null || (tick != null && centre > tick)) {
        continue;
      }
      final TextPainter name = TextPainter(
        text: TextSpan(text: label, style: names),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      if (name.width <= bite.width - _nameInset) {
        name.paint(canvas, Offset(centre - name.width / 2, barHeight + nameGap));
      }
      name.dispose();
    }
  }

  RRect _shape(double left, double right) =>
      RRect.fromLTRBR(left, 0, right, barHeight, Radius.circular(math.min(HisaabRadii.block, (right - left) / 2)));

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  @override
  bool shouldRepaint(TodayBarPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.names != names ||
      oldDelegate.textScaler != textScaler;
}
