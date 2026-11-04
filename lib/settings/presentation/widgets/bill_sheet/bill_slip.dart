import 'package:flutter/material.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';

/// The bill drawn as a paper slip: flat `display` paper with 20dp top corners and a torn
/// bottom edge (UI_DESIGN Fixed bills, D118). [child] is the slip's content.
class BillSlip extends StatelessWidget {
  const BillSlip({super.key, required this.child});

  final Widget child;

  static const double _corner = 20;
  static const double _toothWidth = 14;
  static const double _toothDepth = 8;

  @override
  Widget build(BuildContext context) {
    final Color paper = context.colors.display;
    final Widget slip = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(_corner)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 18, HisaabSpacing.gutter, 14),
            child: child,
          ),
        ),
        CustomPaint(size: const Size.fromHeight(_toothDepth), painter: _TornEdgePainter(paper)),
      ],
    );
    return KeyedSubtree(key: const ValueKey<String>('bill-slip'), child: slip);
  }
}

/// Paints the slip's torn edge: a row of downward teeth in the paper colour.
class _TornEdgePainter extends CustomPainter {
  const _TornEdgePainter(this.paper);

  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final Path teeth = Path()..moveTo(0, 0);
    for (double x = 0; x < size.width; x += BillSlip._toothWidth) {
      final double end = (x + BillSlip._toothWidth).clamp(0, size.width);
      teeth
        ..lineTo((x + end) / 2, size.height)
        ..lineTo(end, 0);
    }
    canvas.drawPath(teeth..close(), Paint()..color = paper);
  }

  @override
  bool shouldRepaint(_TornEdgePainter oldDelegate) => oldDelegate.paper != paper;
}
