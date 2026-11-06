import 'package:flutter/widgets.dart';

/// Clips to the share of the hold key that has filled: [fraction] of its width from the start edge.
class HoldFillClipper extends CustomClipper<Rect> {
  const HoldFillClipper({required this.fraction, required this.textDirection});

  /// 0 (empty) to 1 (full).
  final double fraction;
  final TextDirection textDirection;

  @override
  Rect getClip(Size size) {
    final double width = size.width * fraction.clamp(0, 1);
    return switch (textDirection) {
      TextDirection.ltr => Rect.fromLTWH(0, 0, width, size.height),
      TextDirection.rtl => Rect.fromLTWH(size.width - width, 0, width, size.height),
    };
  }

  @override
  bool shouldReclip(HoldFillClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.textDirection != textDirection;
}
