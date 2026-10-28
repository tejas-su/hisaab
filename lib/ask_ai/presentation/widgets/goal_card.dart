import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';

/// One Ask AI goal (FR-AI-1): outlined, or ink-filled with a marigold check when [selected].
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.label, required this.selected, required this.onPressed});

  static const double _minHeight = 72;

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: label,
    selected: selected,
    onPressed: onPressed,
    builder: (BuildContext context, bool pressed) => Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsetsDirectional.all(HisaabSpacing.l),
      decoration: ShapeDecoration(
        color: selected ? context.colors.ink : (pressed ? context.colors.sunk : context.colors.surface),
        shape: HisaabShapes.squircle(
          HisaabRadii.tile,
          side: BorderSide(color: selected ? context.colors.ink : context.colors.hairline, width: 1.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: selected ? context.colors.background : context.colors.ink),
            ),
          ),
          // why: marigold sits on the ink fill only, never on the bare light background.
          if (selected) ...<Widget>[
            const SizedBox(width: HisaabSpacing.s),
            AppIcon(AppIcons.check, color: context.colors.signal, size: 20),
          ],
        ],
      ),
    ),
  );
}
