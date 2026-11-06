import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [child] out in exactly the space it is given but reports no intrinsic height.
///
/// `SliverFillRemaining` sizes its child to the larger of the space left and the child's
/// intrinsic height. Wrapping a picture in this makes it take only the space left, so it never
/// pushes a screen into scrolling (see `AdaptiveSplit.art`).
class NoIntrinsicHeight extends SingleChildRenderObjectWidget {
  const NoIntrinsicHeight({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoIntrinsicHeight();
}

class _RenderNoIntrinsicHeight extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
