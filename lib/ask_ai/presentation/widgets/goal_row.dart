import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/focus_ring.dart';
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
    // why: rows touch each other and the card's edge, so the ring is drawn inside the row.
    focusInset: const EdgeInsets.all(FocusRing.outset),
    builder: (BuildContext context, bool pressed) => Container(
      color: pressed ? context.colors.sunk : null,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: 9),
      child: Row(
        children: <Widget>[
          GoalWell(icon: icon),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            // why: rows are Regular body text; the pick steps up one weight, alongside the check
            // (case study 02).
            child: Text(
              label,
              style: selected ? HisaabType.emphasized(Theme.of(context).textTheme.bodyLarge) : Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (selected) const GoalCheck(),
        ],
      ),
    ),
  );
}
