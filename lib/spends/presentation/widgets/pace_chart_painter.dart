import 'package:flutter/rendering.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/pace_series.dart';
import 'pace_strokes.dart';

/// Paints the pace chart: gridlines labelled inside the plot, the dotted steady line (stepping up on
/// bill days), the solid spending line and, on the current cycle, the gap bracket at today, the
/// dashed forecast and a marigold today dot (SPEC FR-SP-3, UI_DESIGN §5.4, D133, D135).
///
/// It paints no amounts beside the lines: the gap and the forecast are a line of text under the
/// chart, so they never collide on a narrow phone or at a large text size (D135).
class PaceChartPainter extends CustomPainter {
  const PaceChartPainter({
    required this.series,
    required this.axisLabels,
    required this.labelStyle,
    required this.textScaler,
    required this.colors,
    required this.showToday,
  });

  final PaceSeries series;

  /// The formatted [PaceSeries.axisLabels], e.g. "₹20K", bottom first.
  final List<String> axisLabels;
  final TextStyle labelStyle;

  /// The phone's text size, so the axis labels grow with it (WCAG 1.4.4).
  final TextScaler textScaler;
  final PaceChartColors colors;
  final bool showToday;

  /// Room above the plot's top, so the steady line's end doesn't press on the total.
  static const double topInset = 12;

  /// Room at the plot's right and bottom, so round caps and the today dot aren't clipped.
  static const double inset = 6;

  static const double _labelLift = 2;
  static const double _todayRadius = 5;
  static const double _ringRadius = 4.5;
  static const double _capHalf = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = Rect.fromLTRB(0, topInset, size.width - inset, size.height - inset);
    _grid(canvas, plot);
    PaceStrokes.dashed(canvas, <Offset>[
      _point(plot, 0, Money.zero),
      for (int day = 0; day < series.cycleDays; day++) _point(plot, day + 1, series.steadyThrough(day)),
    ], _stroke(colors.ink2, 2), dash: 2, gap: 4);
    final List<Offset> spent = <Offset>[
      _point(plot, 0, Money.zero),
      for (final (int day, Money total) in series.spentByDay.indexed) _point(plot, day + 1, total),
    ];
    _forecast(canvas, plot);
    _spending(canvas, spent);
    if (showToday) {
      _gap(canvas, plot, spent.last);
      _today(canvas, spent.last);
    }
  }

  /// Where the total [value] at the end of day [dayEnd] (0 is the cycle's start) sits in [plot].
  Offset _point(Rect plot, int dayEnd, Money value) => Offset(
        plot.left + plot.width * dayEnd / series.cycleDays,
        plot.bottom - plot.height * value.amountMinor / series.top.amountMinor,
      );

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  // why: each label sits just above its gridline at the plot's left edge, so the plot keeps the
  // card's full width (HIG: maximise the plot's width); ₹0 is left to the baseline, since its label
  // would sit where the spending line starts (D135). Painted before the lines, which cross over it.
  void _grid(Canvas canvas, Rect plot) {
    for (final (int i, String text) in axisLabels.indexed) {
      final double y = _point(plot, 0, series.axisLabels[i]).dy;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), Paint()..color = colors.hairline);
      if (series.axisLabels[i].amountMinor == 0) {
        continue;
      }
      final TextPainter label = PaceStrokes.layout(text, labelStyle, textScaler);
      label.paint(canvas, Offset(plot.left, y - _labelLift - label.height));
      label.dispose();
    }
  }

  void _spending(Canvas canvas, List<Offset> points) => canvas.drawPath(Path()..addPolygon(points, false), _stroke(colors.ink, 2.5));

  /// The dashed forecast from today, stopped where it meets the budget, with a ring where it runs out.
  void _forecast(Canvas canvas, Rect plot) {
    if (series.forecastByDay.isEmpty) {
      return;
    }
    final List<Offset> points = _untilBudget(plot);
    PaceStrokes.dashed(canvas, points, _stroke(colors.ink, 2), dash: 6, gap: 5);
    if (series.forecast.toNullable() is RunsOut) {
      canvas
        ..drawCircle(points.last, _ringRadius, Paint()..color = colors.surface)
        ..drawCircle(points.last, _ringRadius, _stroke(colors.ink, 2));
    }
  }

  // why: the line stops where the money does, so it meets the budget mid-day rather than overshooting.
  List<Offset> _untilBudget(Rect plot) {
    final int today = series.spentByDay.length - 1;
    final List<Money> line = series.forecastByDay;
    final List<Offset> points = <Offset>[_point(plot, today + 1, line.first)];
    for (int ahead = 1; ahead < line.length; ahead++) {
      final Offset next = _point(plot, today + ahead + 1, line[ahead]);
      if (line[ahead] > series.budget) {
        final double t = (series.budget - line[ahead - 1]).amountMinor / (line[ahead] - line[ahead - 1]).amountMinor;
        return <Offset>[...points, Offset.lerp(points.last, next, t) ?? next];
      }
      points.add(next);
    }
    return points;
  }

  /// A bracket from [today]'s point to the steady line.
  void _gap(Canvas canvas, Rect plot, Offset today) {
    final double steady = _point(plot, 0, series.steadyThrough(series.spentByDay.length - 1)).dy;
    canvas.drawPath(
      Path()
        ..moveTo(today.dx, today.dy)
        ..lineTo(today.dx, steady)
        ..moveTo(today.dx - _capHalf, steady)
        ..lineTo(today.dx + _capHalf, steady),
      _stroke(colors.ink2, 1.5),
    );
  }

  // why: marigold is never bare on the light card, so the dot carries an ink ring.
  void _today(Canvas canvas, Offset point) => canvas
    ..drawCircle(point, _todayRadius, Paint()..color = colors.signal)
    ..drawCircle(point, _todayRadius, _stroke(colors.ink, 1.5));

  @override
  bool shouldRepaint(PaceChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.showToday != showToday ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.colors != colors ||
      oldDelegate.axisLabels.join() != axisLabels.join();
}

/// The colour tokens the pace chart paints with.
typedef PaceChartColors = ({Color ink, Color ink2, Color hairline, Color signal, Color surface});
