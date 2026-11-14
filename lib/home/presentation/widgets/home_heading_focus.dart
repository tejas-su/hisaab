import 'package:flutter/widgets.dart';

/// Offers Home's "Today" heading a [FocusNode] to the Today list, so focus can land there when
/// the missed-log line that opened a tray is removed (SPEC FR-HO-3 Focus). Without one above it,
/// the Today list's heading takes no focus.
class HomeHeadingFocus extends InheritedWidget {
  /// Provides [node] to everything below.
  const HomeHeadingFocus({super.key, required this.node, required super.child});

  final FocusNode node;

  /// The node above [context], or null when there is none.
  static FocusNode? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HomeHeadingFocus>()?.node;

  @override
  bool updateShouldNotify(HomeHeadingFocus oldWidget) => node != oldWidget.node;
}
