import 'package:hisaab/core/widgets/focus_ring.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forces Flutter's focus highlight mode for one test: `alwaysTraditional` is a keyboard, D-pad or
/// switch user, `alwaysTouch` a finger. Restores the automatic strategy afterwards.
void useFocusHighlight(FocusHighlightStrategy strategy) {
  FocusManager.instance.highlightStrategy = strategy;
  addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
}

/// The [CustomPaint] that draws the focus ring of the first [FocusRing] inside [control].
Finder focusRingPaint(Finder control) => find
    .descendant(of: find.descendant(of: control, matching: find.byType(FocusRing)).first, matching: find.byType(CustomPaint))
    .first;

/// Whether the focus ring inside [control] is drawn.
bool showsFocusRing(WidgetTester tester, Finder control) =>
    tester.widget<CustomPaint>(focusRingPaint(control)).foregroundPainter != null;
