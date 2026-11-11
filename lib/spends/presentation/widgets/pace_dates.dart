import 'package:material_ui/material_ui.dart';

import 'pace_chart_painter.dart';
import 'pace_strokes.dart';

/// The pace chart's date row: the cycle's first and last days, and *Today* under today's point
/// (FR-SP-3, D133). A date that would touch *Today* gives way to it.
///
/// It sits under the plot, so the plot keeps its height (D135), and spans the plot's width: the
/// card's left edge to the plot's right inset. [todayAt] is today's end-of-day position as a share
/// of the cycle, or null on a past cycle. The text grows with the phone's text size. Hidden from
/// TalkBack: the card reads as one sentence.
class PaceDates extends StatelessWidget {
  const PaceDates({
    super.key,
    required this.start,
    required this.end,
    required this.today,
    required this.todayAt,
    required this.labelStyle,
    required this.todayStyle,
  });

  final String start;
  final String end;
  final String today;
  final double? todayAt;
  final TextStyle labelStyle;
  final TextStyle todayStyle;

  @override
  Widget build(BuildContext context) {
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextPainter probe = PaceStrokes.layout(today, todayStyle, textScaler);
    final double height = probe.height;
    probe.dispose();
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey<String>('pace-dates'),
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _PaceDatesPainter(this, textScaler)),
      ),
    );
  }
}

class _PaceDatesPainter extends CustomPainter {
  const _PaceDatesPainter(this.row, this.textScaler);

  final PaceDates row;
  final TextScaler textScaler;

  static const double _minGap = 8;

  @override
  void paint(Canvas canvas, Size size) {
    // why: matches the chart's right inset, so *3 Nov* ends where the plot does.
    final double right = size.width - PaceChartPainter.inset;
    final TextPainter start = PaceStrokes.layout(row.start, row.labelStyle, textScaler);
    final TextPainter end = PaceStrokes.layout(row.end, row.labelStyle, textScaler);
    final double? at = row.todayAt;
    Rect? today;
    if (at != null) {
      final TextPainter label = PaceStrokes.layout(row.today, row.todayStyle, textScaler);
      final double x = right * at - label.width / 2;
      today = Offset(PaceStrokes.within(x, label.width, 0, right), 0) & label.size;
      label
        ..paint(canvas, today.topLeft)
        ..dispose();
    }
    final Rect startBox = Offset.zero & start.size;
    final Rect endBox = Offset(right - end.width, 0) & end.size;
    if (today == null || startBox.right + _minGap <= today.left) {
      start.paint(canvas, startBox.topLeft);
    }
    if (today == null || today.right + _minGap <= endBox.left) {
      end.paint(canvas, endBox.topLeft);
    }
    start.dispose();
    end.dispose();
  }

  @override
  bool shouldRepaint(_PaceDatesPainter oldDelegate) =>
      oldDelegate.textScaler != textScaler ||
      oldDelegate.row.start != row.start ||
      oldDelegate.row.end != row.end ||
      oldDelegate.row.today != row.today ||
      oldDelegate.row.todayAt != row.todayAt ||
      oldDelegate.row.labelStyle != row.labelStyle ||
      oldDelegate.row.todayStyle != row.todayStyle;
}
