import 'package:flutter/material.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// A category tile in the Add tray grid: icon over its name in a `sunk` squircle (UI_DESIGN §5.3).
///
/// [flashed] fills it with ink, the 120ms "saved" flash. Positions never change (DECISIONS D13).
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.flashed = false,
  });

  final AppIconData icon;
  final String label;

  /// E.g. "Food. Save"; spoken instead of the plain name.
  final String semanticLabel;

  /// Null while a save is in flight, so double taps are ignored (FR-AD-6).
  final VoidCallback? onPressed;
  final bool flashed;

  @override
  Widget build(BuildContext context) {
    final Color foreground = flashed ? context.colors.background : context.colors.ink;
    return Pressable(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.tileHeight),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.xs, vertical: HisaabSpacing.s),
        decoration: ShapeDecoration(
          color: flashed ? context.colors.ink : (pressed ? context.colors.hairline : context.colors.sunk),
          shape: HisaabShapes.squircle(HisaabRadii.tile),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppIcon(icon, color: foreground),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
