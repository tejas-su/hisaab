import 'package:flutter/material.dart';

import '../design/hisaab_colors.dart';
import '../layout/app_layout.dart';
import '../layout/app_layout_scope.dart';

/// Shortcuts from [BuildContext] to the app's design tokens and adaptive layout.
extension BuildContextExtensions on BuildContext {
  /// The colour tokens of the current theme; light tokens if none are installed (tests).
  HisaabColors get colors => Theme.of(this).extension<HisaabColors>() ?? HisaabColors.light;

  /// The adaptive layout resolved for the current window.
  AppLayout get layout => AppLayoutScope.of(this);
}
