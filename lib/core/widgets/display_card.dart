import 'package:flutter/material.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';

/// The ink "display" card that holds amounts and Day Blocks, like a calculator's readout
/// (UI_DESIGN §3.1). Text inside uses `displayInk` / `displayInk2`.
class DisplayCard extends StatelessWidget {
  const DisplayCard({super.key, required this.child, this.radius = HisaabRadii.card, this.padding});

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.gutter, HisaabSpacing.gutter, 18),
      decoration: ShapeDecoration(
        color: context.colors.display,
        // why: in dark mode the card is barely lighter than the page, so a hairline separates it.
        shape: HisaabShapes.squircle(radius, side: dark ? BorderSide(color: context.colors.hairline) : BorderSide.none),
      ),
      child: child,
    );
  }
}
