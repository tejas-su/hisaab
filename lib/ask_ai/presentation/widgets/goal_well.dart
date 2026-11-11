import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import 'goal_row.dart';

/// The `sunk` icon well at the start of a goal row.
class GoalWell extends StatelessWidget {
  const GoalWell({super.key, required this.icon});

  final AppIconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: GoalRow.well,
    height: GoalRow.well,
    alignment: Alignment.center,
    decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
    child: AppIcon(icon),
  );
}
