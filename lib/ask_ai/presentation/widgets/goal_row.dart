import 'package:flutter/material.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import 'goal_check.dart';
import 'goal_well.dart';

/// One Ask AI goal as a list row (FR-AI-1), with the Today list's geometry: an icon in a `sunk`
/// well, then the label. The pick gets a bold label and an ink check at the end (Apple HIG,
/// D67); it is never filled and never marigold.
class GoalRow extends StatelessWidget {
  const GoalRow({super.key, required this.label, required this.icon, required this.selected, required this.onPressed});

  /// Icon well size, shared with the Today list's rows.
  static const double well = 42;

  final String label;
  final AppIconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: label,
    selected: selected,
    onPressed: onPressed,
    builder: (BuildContext context, bool pressed) => Container(
      color: pressed ? context.colors.sunk : null,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: 9),
      child: Row(
        children: <Widget>[
          GoalWell(icon: icon),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: selected ? FontWeight.w700 : null)),
          ),
          if (selected) const GoalCheck(),
        ],
      ),
    ),
  );
}
