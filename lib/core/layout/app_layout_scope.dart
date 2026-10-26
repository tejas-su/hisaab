import 'package:flutter/widgets.dart';

import 'app_layout.dart';

/// Resolves the [AppLayout] from the window size and display features, and shares it below.
///
/// Rebuilds dependents only when the resolved layout changes, not on every pixel of resize.
class AppLayoutScope extends StatelessWidget {
  const AppLayoutScope({super.key, required this.child});

  final Widget child;

  /// The layout for [context]; a single full-window pane when no scope is above it.
  static AppLayout of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppLayoutInherited>()?.layout ??
      AppLayout.resolve(window: MediaQuery.sizeOf(context));

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.resolve(
      window: MediaQuery.sizeOf(context),
      displayFeatures: MediaQuery.displayFeaturesOf(context),
    );
    return _AppLayoutInherited(layout: layout, child: child);
  }
}

class _AppLayoutInherited extends InheritedWidget {
  const _AppLayoutInherited({required this.layout, required super.child});

  final AppLayout layout;

  @override
  bool updateShouldNotify(_AppLayoutInherited oldWidget) => oldWidget.layout != layout;
}
