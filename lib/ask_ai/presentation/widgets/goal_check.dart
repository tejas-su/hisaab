import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// The ink check that marks the picked goal.
class GoalCheck extends StatelessWidget {
  const GoalCheck({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: HisaabSpacing.s),
    child: AppIcon(AppIcons.check, key: const ValueKey<String>('goal-check'), color: context.colors.ink),
  );
}
