import 'dart:ui' show PathMetric;

import 'package:flutter/rendering.dart';

/// Drawing helpers shared by the pace chart's painters: dashed lines and text.
abstract final class PaceStrokes {
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

  /// Lays out [text] in [style] at the phone's [textScaler], left to right; the caller disposes it.
  static TextPainter layout(String text, TextStyle style, TextScaler textScaler) =>
      TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: textScaler)..layout();

  /// Clamps a label of [width] starting at [left] so it stays within [min] and [max].
  static double within(double left, double width, double min, double max) =>
      left < min ? min : (left + width > max ? max - width : left);
}
