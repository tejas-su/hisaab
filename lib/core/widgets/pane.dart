import 'package:flutter/widgets.dart';

/// Places [child] at [rect] (window coordinates) and keeps it clear of system bars and
/// cutouts only on the window edges the pane actually touches.
///
/// Set [insetTop] to false when [child] draws its own bar behind the status bar, as
/// `TopBarScrollView` does; the inset then stays in [MediaQuery] for the child to read.
class Pane extends StatelessWidget {
  const Pane({super.key, required this.rect, required this.windowSize, required this.child, this.insetTop = true});

  final Rect rect;
  final Size windowSize;
  final Widget child;
  final bool insetTop;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: rect,
        child: SafeArea(
          left: rect.left <= 0,
          top: insetTop && rect.top <= 0,
          right: rect.right >= windowSize.width,
          bottom: rect.bottom >= windowSize.height,
          child: child,
        ),
      );
}
