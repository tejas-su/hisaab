/// Material window width classes, computed from the app window, not the physical screen.
enum WidthClass {
  /// Under 600 dp: phones, folded foldables, split-screen halves.
  compact,

  /// 600–839 dp: unfolded foldables in portrait, small tablets.
  medium,

  /// 840 dp and up: tablets, unfolded foldables in landscape, phones in landscape.
  expanded,
}

/// Window height classes; compact heights get a denser layout.
enum HeightClass {
  /// Under 480 dp: phones in landscape, small multi-window panes.
  compact,

  regular,
}

/// Layout breakpoints and pane sizes in logical pixels (UI_DESIGN §13).
abstract final class LayoutBreakpoints {
  static const double mediumWidth = 600;
  static const double expandedWidth = 840;
  static const double regularHeight = 480;

  /// Content never grows wider than this in a single pane, so lines stay readable.
  static const double singlePaneMaxWidth = 560;

  /// Primary (Home) pane width bounds when two panes sit side by side.
  static const double primaryPaneMinWidth = 360;
  static const double primaryPaneMaxWidth = 480;

  /// Share of the window the primary pane takes before clamping.
  static const double primaryPaneFraction = 0.4;
}

/// Returns the width class for a window [width] in logical pixels.
WidthClass widthClassOf(double width) {
  if (width >= LayoutBreakpoints.expandedWidth) {
    return WidthClass.expanded;
  }
  return width >= LayoutBreakpoints.mediumWidth ? WidthClass.medium : WidthClass.compact;
}

/// Returns the height class for a window [height] in logical pixels.
HeightClass heightClassOf(double height) =>
    height >= LayoutBreakpoints.regularHeight ? HeightClass.regular : HeightClass.compact;
