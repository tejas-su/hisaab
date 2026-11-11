import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Finds a `material_ui` [Tooltip] whose message is [message], in place of `find.byTooltip`.
///
/// why: flutter_test's `find.byTooltip` still matches only `package:flutter/material.dart`'s
/// Tooltip, so a material_ui tooltip with `excludeFromSemantics: true` (the Back button, D57)
/// is invisible to it (D146).
Finder findTooltip(String message) =>
    find.byWidgetPredicate((Widget widget) => widget is Tooltip && widget.message == message);
