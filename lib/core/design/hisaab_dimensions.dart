/// Corner radii (UI_DESIGN §3.5), varied on purpose to show hierarchy.
abstract final class HisaabRadii {
  static const double block = 8;
  static const double chip = 12;
  static const double key = 16;
  static const double tile = 22;
  static const double card = 28;
  static const double tray = 36;

  /// Corner smoothing for continuous (squircle) corners.
  static const double smoothing = 0.6;
}

/// Spacing on a 4 dp grid.
abstract final class HisaabSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double gutter = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Fixed control sizes.
abstract final class HisaabSizes {
  /// Smallest allowed touch target.
  static const double minTouchTarget = 48;
  static const double keypadKeyHeight = 64;
  static const double tileHeight = 96;
  static const double dockHeight = 76;
  static const double iconSize = 24;
  static const double iconStroke = 1.6;
}
