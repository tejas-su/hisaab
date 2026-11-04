import 'package:flutter/material.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';

/// A dashed perforation across the slip, with half-circle notches cut at both edges in the
/// sheet's colour (D118). It sits inside the slip's gutter and draws its notches out to the
/// slip's edges.
class BillPerforation extends StatelessWidget {
  const BillPerforation({super.key});

  static const double _height = 20;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: const Size.fromHeight(_height),
          painter: _PerforationPainter(dash: context.colors.hairline, notch: context.colors.background),
        ),
      );
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.dash, required this.notch});

  final Color dash;
  final Color notch;

  static const double _dash = 6;
  static const double _gap = 4;
  static const double _stroke = 2;
  static const double _notchRadius = 8;
  static const double _clearOfNotch = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;
    final Paint line = Paint()
      ..color = dash
      ..strokeWidth = _stroke;
    final double start = _notchRadius - HisaabSpacing.gutter + _clearOfNotch;
    final double end = size.width + HisaabSpacing.gutter - _notchRadius - _clearOfNotch;
    for (double x = start; x < end; x += _dash + _gap) {
      canvas.drawLine(Offset(x, y), Offset((x + _dash).clamp(start, end), y), line);
    }
    final Paint hole = Paint()..color = notch;
    canvas
      ..drawCircle(Offset(-HisaabSpacing.gutter, y), _notchRadius, hole)
      ..drawCircle(Offset(size.width + HisaabSpacing.gutter, y), _notchRadius, hole);
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) => oldDelegate.dash != dash || oldDelegate.notch != notch;
}
