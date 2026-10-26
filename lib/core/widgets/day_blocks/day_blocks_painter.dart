import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../design/hisaab_dimensions.dart';
import 'day_blocks_data.dart';
import 'day_blocks_layout.dart';

/// The colours [DayBlocksPainter] uses, taken from the hero's display tokens.
final class DayBlocksColors {
  const DayBlocksColors({required this.signal, required this.idle, required this.outline});

  final Color signal;
  final Color idle;

  /// Outline and hatch for the over states (`displayInk2`).
  final Color outline;
}

/// Paints the Day Blocks row (SPEC BR-6, UI_DESIGN §3.3) for an animated [data] snapshot.
///
/// [assembled] runs 0→1 as the blocks slide in after onboarding; 1 means fully drawn.
class DayBlocksPainter extends CustomPainter {
  DayBlocksPainter({
    required this.data,
    required this.colors,
    required this.moreLabel,
    this.assembled = 1,
  });

  final DayBlocksData data;
  final DayBlocksColors colors;

  /// The "+N" label, laid out, for when not every day fits.
  final TextPainter moreLabel;
  final double assembled;

  static const double _stroke = 1.5;
  static const double _hatchSpacing = 6;
  static const Radius _radius = Radius.circular(HisaabRadii.block);

  @override
  void paint(Canvas canvas, Size size) {
    final DayBlocksLayout layout =
        DayBlocksLayout.of(count: data.count, width: size.width, labelWidth: moreLabel.width);
    for (final (int index, ({double left, double width}) block) in layout.blocks.indexed) {
      final double appear = _appearance(index, layout.blocks.length);
      if (appear <= 0) {
        continue;
      }
      if (index == 0) {
        _paintToday(canvas, blockRect(block, size.height, appear));
      } else {
        _paintLater(canvas, block, size.height, appear);
      }
    }
    if (layout.hiddenCount > 0) {
      moreLabel.paint(canvas, Offset(layout.labelLeft, (size.height - moreLabel.height) / 2));
    }
  }

  // why: a staggered entrance; block i starts once the previous ones are partly in.
  double _appearance(int index, int count) {
    if (assembled >= 1) {
      return 1;
    }
    const double overlap = 3;
    return (assembled * (count + overlap) - index).clamp(0, overlap) / overlap;
  }

  void _paintToday(Canvas canvas, Rect rect) {
    final RRect shape = RRect.fromRectAndRadius(rect, _radius);
    switch (data.style) {
      case DayBlocksStyle.onTrack:
        canvas.drawRRect(shape, Paint()..color = colors.idle);
        _paintFill(canvas, shape, data.todayFill);
      case DayBlocksStyle.preview:
        canvas.drawRRect(shape, Paint()..color = colors.signal);
      case DayBlocksStyle.slowDown:
        _paintFill(canvas, shape, data.todayFill);
        canvas.drawRRect(shape.deflate(_stroke / 2), _outline(colors.signal));
      case DayBlocksStyle.overToday:
        _paintHatch(canvas, shape);
        canvas.drawRRect(shape.deflate(_stroke / 2), _outline(colors.outline));
      case DayBlocksStyle.overCycle:
        canvas.drawRRect(shape.deflate(_stroke / 2), _outline(colors.outline));
    }
  }

  void _paintLater(Canvas canvas, ({double left, double width}) block, double rowHeight, double appear) {
    if (data.style == DayBlocksStyle.overCycle) {
      canvas.drawRRect(RRect.fromRectAndRadius(blockRect(block, rowHeight, appear), _radius).deflate(_stroke / 2), _outline(colors.idle));
      return;
    }
    if (data.laterHeight < 1) {
      final RRect ghost = RRect.fromRectAndRadius(blockRect(block, rowHeight, appear), _radius);
      canvas.drawRRect(ghost.deflate(0.5), _outline(colors.idle, width: 1));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect(block, rowHeight, data.laterHeight * appear), _radius),
      Paint()..color = colors.idle,
    );
  }

  void _paintFill(Canvas canvas, RRect shape, double fill) {
    if (fill <= 0) {
      return;
    }
    final Rect outer = shape.outerRect;
    final double height = outer.height * fill.clamp(0, 1);
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(Rect.fromLTWH(outer.left, outer.bottom - height, outer.width, height), Paint()..color = colors.signal)
      ..restore();
  }

  void _paintHatch(Canvas canvas, RRect shape) {
    final Rect outer = shape.outerRect;
    final Paint line = Paint()
      ..color = colors.idle
      ..strokeWidth = 2;
    canvas
      ..save()
      ..clipRRect(shape);
    final double reach = outer.width + outer.height;
    for (double x = -outer.height; x < reach; x += _hatchSpacing) {
      canvas.drawLine(Offset(outer.left + x, outer.bottom), Offset(outer.left + x + outer.height, outer.top), line);
    }
    canvas.restore();
  }

  Paint _outline(Color color, {double width = _stroke}) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(width, 1);

  @override
  bool shouldRepaint(DayBlocksPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.assembled != assembled ||
      oldDelegate.colors.signal != colors.signal ||
      oldDelegate.colors.idle != colors.idle ||
      oldDelegate.colors.outline != colors.outline ||
      oldDelegate.moreLabel.text != moreLabel.text;
}
