import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Paints a faint, still grain of single dots in [color] under the month story's line art.
class StoryGrainPainter extends CustomPainter {
  const StoryGrainPainter({required this.color});

  final Color color;

  // why: sparser than the hero's grain; the story's art is large, so the grain only adds tooth.
  static const double _grainArea = 90;

  // why: a fixed seed keeps the grain identical on every paint, so it never shimmers.
  static const int _seed = 11;

  /// How many dots a grain of [size] holds.
  static int dotCount(Size size) => (size.width * size.height / _grainArea).floor();

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random random = math.Random(_seed);
    final Float32List points = Float32List.fromList(
      List<double>.generate(dotCount(size) * 2, (int i) => random.nextDouble() * (i.isEven ? size.width : size.height)),
    );
    final Paint dot = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawRawPoints(ui.PointMode.points, points, dot);
  }

  @override
  bool shouldRepaint(StoryGrainPainter oldDelegate) => oldDelegate.color != color;
}
