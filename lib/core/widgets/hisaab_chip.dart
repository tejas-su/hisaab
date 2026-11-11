import 'package:material_ui/material_ui.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_colors.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// An outlined chip: quick-add amounts, the date and note chips, onboarding choices.
///
/// A fill with no edge: [HisaabColors.control] on the page, or [HisaabColors.hairline] when
/// [onSurface] (D100). [selected] fills it ink with page-coloured text and a trailing check (D100).
/// [detail] adds a second, quieter line (e.g. an added bill). A null [onPressed] disables it and
/// greys its label.
class HisaabChip extends StatelessWidget {
  const HisaabChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.icon,
    this.trailingIcon,
    this.detail,
    this.selected = false,
    this.expand = false,
    this.onSurface = false,
    this.checksWhenSelected = true,
  });

  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final AppIconData? trailingIcon;
  final String? detail;
  final bool selected;

  /// Fill the available width, for big onboarding choices.
  final bool expand;

  /// Whether [selected] adds the trailing check. Turn it off only where the ink fill plus a
  /// [detail] line already say the chip is picked and the width is tight (the bills grid).
  final bool checksWhenSelected;

  /// Set when the chip sits on a [HisaabColors.surface] layer (the Add tray, a sheet, a card).
  ///
  /// The page's [HisaabColors.control] fill equals the surface in light, so there the chip would
  /// vanish; it keeps the [HisaabColors.hairline] step instead and no pressed fill (D100).
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final Color foreground = _foreground(context);
    final TextTheme text = Theme.of(context).textTheme;
    final AppIconData? leading = icon;
    final AppIconData? trailing = trailingIcon ?? (selected && checksWhenSelected && leading == null ? AppIcons.check : null);
    final String? second = detail;
    return Pressable(
      semanticLabel: semanticLabel ?? <String?>[label, second].whereType<String>().join(', '),
      selected: selected ? true : null,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget, minWidth: HisaabSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.m, vertical: HisaabSpacing.xs),
        decoration: ShapeDecoration(
          color: _fill(context, pressed: pressed),
          shape: HisaabShapes.squircle(HisaabRadii.chip),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (leading != null) ...<Widget>[AppIcon(leading, color: foreground, size: 20), const SizedBox(width: HisaabSpacing.s)],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: expand ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: <Widget>[
                  Text(label, style: text.labelLarge?.copyWith(color: foreground, fontSize: 15)),
                  if (second != null)
                    Text(second, style: text.bodySmall?.copyWith(color: selected ? foreground : context.colors.ink2)),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[const SizedBox(width: HisaabSpacing.xs), AppIcon(trailing, color: foreground, size: 18)],
          ],
        ),
      ),
    );
  }

  // why: chips are fill-only (D88). On the page a chip rests one layer up, on control, and a press
  // steps it to sunk (D97, D100); on a surface layer it keeps hairline and only shrinks. A pick fills
  // ink, the real dark of the screen, so it reads as chosen without relying on the check (D100).
  // A disabled chip has no fill.
  Color? _fill(BuildContext context, {required bool pressed}) {
    final HisaabColors colors = context.colors;
    if (onPressed == null) {
      return null;
    }
    if (selected) {
      return colors.ink;
    }
    if (onSurface) {
      return colors.hairline;
    }
    return pressed ? colors.sunk : colors.control;
  }

  Color _foreground(BuildContext context) {
    if (onPressed == null) {
      return context.colors.ink2;
    }
    return selected ? context.colors.background : context.colors.ink;
  }
}
