import 'dart:ui' show PathMetric;

import 'package:flutter/rendering.dart';

import '../../../core/money/money.dart';
import '../../domain/entities/pace_series.dart';

/// Paints the pace chart: labelled gridlines, the dotted steady line (stepping up on bill days), the solid spending line
/// and, on the current cycle, a marigold today dot (SPEC FR-SP-3, UI_DESIGN §5.4).
class PaceChartPainter extends CustomPainter {
  const PaceChartPainter({
    required this.series,
    required this.axisLabels,
    required this.labelStyle,
    required this.ink,
    required this.ink2,
    required this.hairline,
    required this.signal,
    required this.showToday,
  });

  final PaceSeries series;

  /// The formatted [PaceSeries.axisLabels], e.g. "₹20K", bottom first.
  final List<String> axisLabels;
  final TextStyle labelStyle;
  final Color ink;
  final Color ink2;
  final Color hairline;
  final Color signal;
  final bool showToday;

  static const double _labelGap = 8;
  static const double _inset = 6;
  static const double _dash = 2;
  static const double _dashGap = 4;
  static const double _todayRadius = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final List<TextPainter> labels = axisLabels
        .map((String text) => TextPainter(text: TextSpan(text: text, style: labelStyle), textDirection: TextDirection.ltr)..layout())
        .toList();
    final double labelWidth = labels.fold(0.0, (double widest, TextPainter p) => p.width > widest ? p.width : widest);
    final Rect plot = Rect.fromLTRB(labelWidth + _labelGap, _inset, size.width - _inset, size.height - _inset);
    _grid(canvas, plot, labels, labelWidth);
    _dotted(canvas, <Offset>[
      _point(plot, 0, Money.zero),
      for (int day = 0; day < series.cycleDays; day++) _point(plot, day + 1, series.steadyThrough(day)),
    ]);
    final List<Offset> spent = <Offset>[
      _point(plot, 0, Money.zero),
      for (final (int day, Money total) in series.spentByDay.indexed) _point(plot, day + 1, total),
    ];
    _spending(canvas, spent);
    if (showToday) {
      _today(canvas, spent.last);
    }
    for (final TextPainter label in labels) {
      label.dispose();
    }
  }

  /// Where the total [value] at the end of day [dayEnd] (0 is the cycle's start) sits in [plot].
  Offset _point(Rect plot, int dayEnd, Money value) => Offset(
        plot.left + plot.width * dayEnd / series.cycleDays,
        plot.bottom - plot.height * value.amountMinor / series.top.amountMinor,
      );

  void _grid(Canvas canvas, Rect plot, List<TextPainter> labels, double labelWidth) {
    for (final (int i, TextPainter label) in labels.indexed) {
      final double y = _point(plot, 0, series.axisLabels[i]).dy;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), Paint()..color = hairline);
      label.paint(canvas, Offset(labelWidth - label.width, y - label.height / 2));
    }
  }

  void _spending(Canvas canvas, List<Offset> points) => canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

  // why: marigold is never bare on the light card, so the dot carries an ink ring.
  void _today(Canvas canvas, Offset point) => canvas
    ..drawCircle(point, _todayRadius, Paint()..color = signal)
    ..drawCircle(
      point,
      _todayRadius,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

  // why: the steady line steps up on bill days (D129), so the dashes walk the whole path; one
  // metric keeps their rhythm even across the corners.
  void _dotted(Canvas canvas, List<Offset> points) {
    final Paint paint = Paint()
      ..color = ink2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final PathMetric metric in (Path()..addPolygon(points, false)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _dashGap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(PaceChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.showToday != showToday ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.ink != ink ||
      oldDelegate.ink2 != ink2 ||
      oldDelegate.hairline != hairline ||
      oldDelegate.signal != signal ||
      oldDelegate.axisLabels.join() != axisLabels.join();
}
