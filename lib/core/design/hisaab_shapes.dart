import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/widgets.dart';

import 'hisaab_dimensions.dart';

/// Continuous-corner (squircle) shapes at the token radii (UI_DESIGN §3.5).
abstract final class HisaabShapes {
  /// A squircle with [radius] on every corner and an optional outline [side].
  static SmoothRectangleBorder squircle(double radius, {BorderSide side = BorderSide.none}) => SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: radius, cornerSmoothing: HisaabRadii.smoothing)),
        side: side,
      );

  /// The tray's shape: rounded on top only.
  static SmoothRectangleBorder trayTop() => const SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius.vertical(
          top: SmoothRadius(cornerRadius: HisaabRadii.tray, cornerSmoothing: HisaabRadii.smoothing),
        ),
      );
}
