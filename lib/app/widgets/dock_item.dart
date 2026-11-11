import 'package:material_ui/material_ui.dart';

import '../../core/design/app_icon.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/hisaab_dimensions.dart';
import '../../core/extensions/build_context_extensions.dart';
import '../../core/widgets/focus_ring.dart';

/// One dock destination: icon above its label, filled with `sunk` when selected.
class DockItem extends StatelessWidget {
  const DockItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final AppIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  static const double _width = HisaabSizes.minTouchTarget;
  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected ? context.colors.ink : context.colors.ink2;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // why: excludeSemantics drops the InkWell's own tap action, so expose it here.
      onTap: onPressed,
      excludeSemantics: true,
      child: FocusRing(radius: HisaabRadii.key, child: _item(context, foreground)),
    );
  }

  Widget _item(BuildContext context, Color foreground) => Material(
        color: selected ? context.colors.sunk : context.colors.clear,
        borderRadius: BorderRadius.circular(HisaabRadii.key),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          // why: focus is the ring, never a fill that reads like the selected item (D99).
          focusColor: context.colors.clear,
          // why: minimum, not fixed, size — labels grow with the system text scale (SPEC E12).
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: _width, minHeight: _height),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: HisaabSpacing.xs),
                AppIcon(icon, color: foreground),
                const SizedBox(height: 2),
                // why: at the largest text sizes, or with long translated labels, shrink rather
                // than overflow the fixed-width dock.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
                ),
                const SizedBox(height: HisaabSpacing.xs),
              ],
            ),
          ),
        ),
      );
}
