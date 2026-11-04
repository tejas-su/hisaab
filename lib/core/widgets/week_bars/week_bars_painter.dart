import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';

import '../../design/hisaab_dimensions.dart';
import 'week_bars_data.dart';

/// The colours [WeekBarsPainter] uses, taken from the hero's display tokens.
final class WeekBarsColors extends Equatable {
  const WeekBarsColors({
    required this.past,
    required this.signal,
    required this.edge,
    required this.tick,
    required this.notch,
    required this.idle,
  });

  /// Past days' fill and hatch (`displayInk2`).
  final Color past;
  final Color signal;

  /// Edge around today's marigold (`displayEdge`); transparent draws none.
  final Color edge;

  /// The share tick (`displayInk`).
  final Color tick;

  /// The card colour cut round the tick and behind the hatch (`display`).
  final Color notch;

  /// Future days' stubs (`blockIdle`).
  final Color idle;

  @override
  List<Object?> get props => <Object?>[past, signal, edge, tick, notch, idle];
}

/// Paints seven weekday bars with a share tick each and the part above it hatched (SPEC BR-6a).
///
/// [growth] runs 0→1 as the bars rise from the baseline; columns nearer today rise first.
class WeekBarsPainter extends CustomPainter {
  const WeekBarsPainter({required this.data, required this.colors, this.growth = 1});

  final WeekBarsData data;
  final WeekBarsColors colors;
  final double growth;

  /// Gap between columns; the same as the Day Blocks' (BR-6).
  static const double gap = 6;
  static const double stubHeight = 6;
  static const double zeroLine = 2;
  static const double tickThickness = 2;
  static const double edgeWidth = 1.5;

  /// How much later each column starts rising, per column away from today.
  static const double stagger = 0.07;
  static const double _tickOverhang = 2;
  static const double _hatchSpacing = 5;

  /// Left edge and width of column [index] in a row [width] wide.
  static ({double left, double width}) column(int index, double width) {
    final double columnWidth = (width - gap * 6) / 7;
    return (left: index * (columnWidth + gap), width: columnWidth);
  }

  /// How far column [index] has risen, 0–1, at [growth]: today's first, then outward.
  double progressOf(int index) {
    final double delay = (index - data.todayIndex).abs() * stagger;
    return ((growth - delay) / (1 - stagger * 6)).clamp(0, 1).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < data.bars.length; i++) {
      final ({double left, double width}) slot = column(i, size.width);
      _paintBar(canvas, data.bars[i], Rect.fromLTWH(slot.left, 0, slot.width, size.height), progressOf(i));
    }
  }

  void _paintBar(Canvas canvas, WeekBar bar, Rect slot, double progress) {
    switch (bar.kind) {
      case WeekBarKind.none:
        return;
      case WeekBarKind.future:
        _fillFromBase(canvas, slot, stubHeight * progress, colors.idle, stubHeight / 2);
      case WeekBarKind.past || WeekBarKind.today:
        _paintSpending(canvas, bar, slot, progress);
    }
  }

  void _paintSpending(Canvas canvas, WeekBar bar, Rect slot, double progress) {
    final double scale = slot.height * progress;
    final double solidTop = math.min(bar.spent, bar.share) * scale;
    final Color fill = bar.kind == WeekBarKind.today ? colors.signal : colors.past;
    if (bar.spent == 0) {
      _fillFromBase(canvas, slot, zeroLine * progress, colors.past, zeroLine / 2);
    } else {
      _fillFromBase(canvas, slot, solidTop, fill, HisaabRadii.block);
      if (bar.kind == WeekBarKind.today) {
        _edge(canvas, _fromBase(slot, solidTop));
      }
    }
    if (bar.isOver) {
      _hatch(canvas, Rect.fromLTRB(slot.left, slot.bottom - bar.spent * scale, slot.right, slot.bottom - solidTop));
    }
    _tick(canvas, slot, slot.bottom - bar.share * scale);
  }

  Rect _fromBase(Rect slot, double height) => Rect.fromLTRB(slot.left, slot.bottom - height, slot.right, slot.bottom);

  void _fillFromBase(Canvas canvas, Rect slot, double height, Color color, double radius) {
    if (height <= 0) {
      return;
    }
    final double r = math.min(radius, height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(_fromBase(slot, height), Radius.circular(r)), Paint()..color = color);
  }

  void _edge(Canvas canvas, Rect area) {
    if (colors.edge.a == 0 || area.height <= 0) {
      return;
    }
    final double r = math.min(HisaabRadii.block, area.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(area.deflate(edgeWidth / 2), Radius.circular(r)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth
        ..color = colors.edge,
    );
  }

  void _hatch(Canvas canvas, Rect area) {
    final Paint line = Paint()
      ..color = colors.past
      ..strokeWidth = edgeWidth;
    canvas
      ..save()
      ..clipRect(area)
      ..drawRect(area, Paint()..color = colors.notch);
    for (double x = area.left - area.height; x < area.right; x += _hatchSpacing) {
      canvas.drawLine(Offset(x, area.bottom), Offset(x + area.height, area.top), line);
    }
    canvas
      ..drawRect(
        area.deflate(edgeWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = edgeWidth
          ..color = colors.past,
      )
      ..restore();
  }

  void _tick(Canvas canvas, Rect slot, double y) {
    final Rect tick = Rect.fromLTRB(slot.left - _tickOverhang, y - tickThickness / 2, slot.right + _tickOverhang, y + tickThickness / 2);
    canvas
      ..drawRect(tick.inflate(1), Paint()..color = colors.notch)
      ..drawRect(tick, Paint()..color = colors.tick);
  }

  @override
  bool shouldRepaint(WeekBarsPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.growth != growth || oldDelegate.colors != colors;
}
