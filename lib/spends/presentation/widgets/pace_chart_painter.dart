import 'package:flutter/rendering.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/pace_series.dart';
import 'pace_chart_words.dart';
import 'pace_strokes.dart';

/// Paints the pace chart: labelled gridlines, the dotted steady line (stepping up on bill days), the
/// solid spending line and, on the current cycle, the gap at today, the dashed forecast and a
/// marigold today dot (SPEC FR-SP-3, UI_DESIGN §5.4, D133).
class PaceChartPainter extends CustomPainter {
  const PaceChartPainter({
    required this.series,
    required this.axisLabels,
    required this.labelStyle,
    required this.markStyle,
    required this.words,
    required this.colors,
    required this.showToday,
  });

  final PaceSeries series;

  /// The formatted [PaceSeries.axisLabels], e.g. "₹20K", bottom first.
  final List<String> axisLabels;
  final TextStyle labelStyle;

  /// The style of [words] on the plot.
  final TextStyle markStyle;
  final PaceChartWords words;
  final PaceChartColors colors;
  final bool showToday;

  static const double _labelGap = 8;
  static const double _inset = 6;
  static const double _markGap = 8;
  static const double _todayRadius = 5;
  static const double _ringRadius = 4.5;
  static const double _capHalf = 3;

  /// Where the plot starts: the widest axis label plus a gap. The date row lines up with it.
  static double plotLeft(List<String> axisLabels, TextStyle labelStyle) => axisLabels.fold(0.0, (double widest, String text) {
        final TextPainter label = PaceStrokes.layout(text, labelStyle);
        final double width = label.width;
        label.dispose();
        return width > widest ? width : widest;
      }) +
      _labelGap;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = Rect.fromLTRB(plotLeft(axisLabels, labelStyle), _inset, size.width - _inset, size.height - _inset);
    _grid(canvas, plot);
    PaceStrokes.dashed(canvas, <Offset>[
      _point(plot, 0, Money.zero),
      for (int day = 0; day < series.cycleDays; day++) _point(plot, day + 1, series.steadyThrough(day)),
    ], _stroke(colors.ink2, 2), dash: 2, gap: 4);
    final List<Offset> spent = <Offset>[
      _point(plot, 0, Money.zero),
      for (final (int day, Money total) in series.spentByDay.indexed) _point(plot, day + 1, total),
    ];
    _forecast(canvas, plot, size);
    _spending(canvas, spent);
    final String? gap = words.gap;
    if (gap != null) {
      _gap(canvas, plot, size, (today: spent.last, text: gap));
    }
    if (showToday) {
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

  void _grid(Canvas canvas, Rect plot) {
    for (final (int i, String text) in axisLabels.indexed) {
      final double y = _point(plot, 0, series.axisLabels[i]).dy;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), Paint()..color = colors.hairline);
      final TextPainter label = PaceStrokes.layout(text, labelStyle);
      label.paint(canvas, Offset(plot.left - _labelGap - label.width, y - label.height / 2));
      label.dispose();
    }
  }

  void _spending(Canvas canvas, List<Offset> points) => canvas.drawPath(Path()..addPolygon(points, false), _stroke(colors.ink, 2.5));

  /// The dashed forecast from today, stopped where it meets the budget, with its words at the end.
  void _forecast(Canvas canvas, Rect plot, Size size) {
    final String? text = words.forecast;
    if (series.forecastByDay.isEmpty || text == null) {
      return;
    }
    final List<Offset> points = _untilBudget(plot);
    PaceStrokes.dashed(canvas, points, _stroke(colors.ink, 2), dash: 6, gap: 5);
    final bool runsOut = series.forecast.toNullable() is RunsOut;
    if (runsOut) {
      canvas
        ..drawCircle(points.last, _ringRadius, Paint()..color = colors.surface)
        ..drawCircle(points.last, _ringRadius, _stroke(colors.ink, 2));
    }
    final TextPainter label = PaceStrokes.layout(text, markStyle);
    final double right = runsOut ? points.last.dx - _markGap : plot.right;
    final double top = runsOut ? points.last.dy + _markGap : points.last.dy - _markGap - label.height;
    PaceStrokes.tag(canvas, label, _clamped(label, Offset(right - label.width, top), plot, size), colors.surface);
    label.dispose();
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

  /// A bracket from today's point to the steady line, and [mark]'s words for how far apart they are.
  void _gap(Canvas canvas, Rect plot, Size size, ({Offset today, String text}) mark) {
    final Offset today = mark.today;
    final double steady = _point(plot, 0, series.steadyThrough(series.spentByDay.length - 1)).dy;
    canvas.drawPath(
      Path()
        ..moveTo(today.dx, today.dy)
        ..lineTo(today.dx, steady)
        ..moveTo(today.dx - _capHalf, steady)
        ..lineTo(today.dx + _capHalf, steady),
      _stroke(colors.ink2, 1.5),
    );
    final TextPainter label = PaceStrokes.layout(mark.text, markStyle);
    final bool toTheLeft = today.dx > plot.center.dx;
    final double left = toTheLeft ? today.dx - _markGap - label.width : today.dx + _markGap;
    final Offset at = Offset(left, (today.dy + steady - label.height) / 2);
    PaceStrokes.tag(canvas, label, _clamped(label, at, plot, size), colors.surface);
    label.dispose();
  }

  Offset _clamped(TextPainter label, Offset at, Rect plot, Size size) => Offset(
        PaceStrokes.within(at.dx, label.width, plot.left, size.width),
        PaceStrokes.within(at.dy, label.height, 0, plot.bottom),
      );

  // why: marigold is never bare on the light card, so the dot carries an ink ring.
  void _today(Canvas canvas, Offset point) => canvas
    ..drawCircle(point, _todayRadius, Paint()..color = colors.signal)
    ..drawCircle(point, _todayRadius, _stroke(colors.ink, 1.5));

  @override
  bool shouldRepaint(PaceChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.showToday != showToday ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.markStyle != markStyle ||
      oldDelegate.words != words ||
      oldDelegate.colors != colors ||
      oldDelegate.axisLabels.join() != axisLabels.join();
}

/// The colour tokens the pace chart paints with.
typedef PaceChartColors = ({Color ink, Color ink2, Color hairline, Color signal, Color surface});
