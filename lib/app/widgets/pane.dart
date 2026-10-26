import 'package:flutter/widgets.dart';

/// Places [child] at [rect] (window coordinates) and keeps it clear of system bars and
/// cutouts only on the window edges the pane actually touches.
class Pane extends StatelessWidget {
  const Pane({super.key, required this.rect, required this.windowSize, required this.child});

  final Rect rect;
  final Size windowSize;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: rect,
        child: SafeArea(
          left: rect.left <= 0,
          top: rect.top <= 0,
          right: rect.right >= windowSize.width,
          bottom: rect.bottom >= windowSize.height,
          child: child,
        ),
      );
}
