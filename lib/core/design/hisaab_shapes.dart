import 'package:flutter/widgets.dart';

import 'hisaab_dimensions.dart';

/// Continuous-corner (squircle) shapes at the token radii (UI_DESIGN §3.5).
abstract final class HisaabShapes {
  /// A squircle with [radius] on every corner and an optional outline [side].
  static RoundedSuperellipseBorder squircle(double radius, {BorderSide side = BorderSide.none}) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius), side: side);

  /// The tray's shape: rounded on top only.
  static RoundedSuperellipseBorder trayTop() => const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HisaabRadii.tray)),
      );

  /// The hero's lift: one soft shadow in [color], below the card and pulled in at the sides, so
  /// the hero alone reads as raised (D106).
  static List<BoxShadow> raised(Color color) => <BoxShadow>[
        BoxShadow(color: color, offset: const Offset(0, 10), blurRadius: 28, spreadRadius: -12),
      ];
}
