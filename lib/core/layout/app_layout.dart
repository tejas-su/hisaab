import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'window_class.dart';

/// How the app's panes are placed in the window, in window coordinates.
sealed class PaneArrangement extends Equatable {
  const PaneArrangement();
}

/// One pane: full width on compact windows, a centred readable column on wider ones.
final class SinglePane extends PaneArrangement {
  const SinglePane(this.content);

  final Rect content;

  @override
  List<Object?> get props => <Object?>[content];
}

/// Two panes side by side: Home ([primary]) and the secondary screen.
final class SideBySidePanes extends PaneArrangement {
  const SideBySidePanes({required this.primary, required this.secondary, required this.splitByHinge});

  final Rect primary;
  final Rect secondary;

  /// Whether the split follows a physical fold or hinge rather than the width breakpoint.
  final bool splitByHinge;

  @override
  List<Object?> get props => <Object?>[primary, secondary, splitByHinge];
}

/// A half-opened foldable lying flat: content above the fold, controls below it.
final class TabletopPanes extends PaneArrangement {
  const TabletopPanes({required this.top, required this.bottom});

  final Rect top;
  final Rect bottom;

  @override
  List<Object?> get props => <Object?>[top, bottom];
}

/// The resolved adaptive layout for a window: size classes plus pane placement.
final class AppLayout extends Equatable {
  const AppLayout({required this.widthClass, required this.heightClass, required this.panes});

  /// Resolves the layout for a [window] of logical size, avoiding any fold or hinge in
  /// [displayFeatures] (whose bounds are in the same window coordinates).
  factory AppLayout.resolve({
    required Size window,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) =>
      AppLayout(
        widthClass: widthClassOf(window.width),
        heightClass: heightClassOf(window.height),
        panes: _arrange(window, displayFeatures.where(_isSeparator).toList()),
      );

  final WidthClass widthClass;
  final HeightClass heightClass;
  final PaneArrangement panes;

  /// Whether navigation uses the bottom dock; with two panes both screens are visible.
  bool get showsDock => panes is! SideBySidePanes;

  static bool _isSeparator(DisplayFeature feature) =>
      feature.type == DisplayFeatureType.fold || feature.type == DisplayFeatureType.hinge;

  static PaneArrangement _arrange(Size window, List<DisplayFeature> separators) =>
      _splitAtVerticalFold(window, separators) ??
      _tabletop(window, separators) ??
      (window.width >= LayoutBreakpoints.expandedWidth ? _splitByWidth(window) : _single(window));

  static PaneArrangement? _splitAtVerticalFold(Size window, List<DisplayFeature> separators) {
    if (window.width < LayoutBreakpoints.mediumWidth) {
      return null;
    }
    final Iterable<Rect> folds = separators
        .map((DisplayFeature feature) => feature.bounds)
        .where((Rect bounds) => _spansHeight(bounds, window));
    if (folds.isEmpty) {
      return null;
    }
    final Rect fold = folds.first;
    return SideBySidePanes(
      primary: Rect.fromLTRB(0, 0, fold.left, window.height),
      secondary: Rect.fromLTRB(fold.right, 0, window.width, window.height),
      splitByHinge: true,
    );
  }

  static PaneArrangement? _tabletop(Size window, List<DisplayFeature> separators) {
    final Iterable<Rect> folds = separators
        .where((DisplayFeature feature) => feature.state == DisplayFeatureState.postureHalfOpened)
        .map((DisplayFeature feature) => feature.bounds)
        .where((Rect bounds) => _spansWidth(bounds, window));
    if (folds.isEmpty) {
      return null;
    }
    final Rect fold = folds.first;
    return TabletopPanes(
      top: Rect.fromLTRB(0, 0, window.width, fold.top),
      bottom: Rect.fromLTRB(0, fold.bottom, window.width, window.height),
    );
  }

  static PaneArrangement _splitByWidth(Size window) {
    final double primaryWidth = (window.width * LayoutBreakpoints.primaryPaneFraction)
        .clamp(LayoutBreakpoints.primaryPaneMinWidth, LayoutBreakpoints.primaryPaneMaxWidth);
    return SideBySidePanes(
      primary: Rect.fromLTWH(0, 0, primaryWidth, window.height),
      secondary: Rect.fromLTRB(primaryWidth, 0, window.width, window.height),
      splitByHinge: false,
    );
  }

  static PaneArrangement _single(Size window) {
    if (window.width < LayoutBreakpoints.mediumWidth) {
      return SinglePane(Offset.zero & window);
    }
    const double width = LayoutBreakpoints.singlePaneMaxWidth;
    return SinglePane(Rect.fromLTWH((window.width - width) / 2, 0, width, window.height));
  }

  static bool _spansHeight(Rect bounds, Size window) =>
      bounds.top <= 0 && bounds.bottom >= window.height && bounds.left > 0 && bounds.right < window.width;

  static bool _spansWidth(Rect bounds, Size window) =>
      bounds.left <= 0 && bounds.right >= window.width && bounds.top > 0 && bounds.bottom < window.height;

  @override
  List<Object?> get props => <Object?>[widthClass, heightClass, panes];
}
