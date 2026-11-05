import 'dart:ui' show PathMetric;

import 'package:flutter/rendering.dart';

/// Drawing helpers shared by the pace chart's painters: dashed lines and labels on the card.
abstract final class PaceStrokes {
  static const double _tagPadding = 3;
  static const double _tagRadius = 4;

  /// Strokes [points] as a polyline of [dash]-long dashes, [gap] apart, with [paint].
  // why: the lines step up on bill days (D129), so the dashes walk the whole path; one metric
  // keeps their rhythm even across the corners.
  static void dashed(Canvas canvas, List<Offset> points, Paint paint, {required double dash, required double gap}) {
    for (final PathMetric metric in (Path()..addPolygon(points, false)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  /// Paints [label] with its top-left at [at], on a [surface] patch so it reads over the lines.
  static void tag(Canvas canvas, TextPainter label, Offset at, Color surface) {
    final Rect box = (at & label.size).inflate(_tagPadding);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(_tagRadius)), Paint()..color = surface);
    label.paint(canvas, at);
  }

  /// Lays out [text] in [style], left to right; the caller disposes it.
  static TextPainter layout(String text, TextStyle style) =>
      TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();

  /// Clamps a label of [width] starting at [left] so it stays within [min] and [max].
  static double within(double left, double width, double min, double max) =>
      left < min ? min : (left + width > max ? max - width : left);
}
