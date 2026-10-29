import 'package:flutter/material.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// An outlined chip: quick-add amounts, the date and note chips, onboarding choices.
///
/// A hairline fill with no edge. [selected] fills it ink2 with page-coloured text and a trailing check (D89). [detail] adds a second, quieter line (e.g. an added bill).
/// A null [onPressed] disables it and greys its label.
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

  @override
  Widget build(BuildContext context) {
    final Color foreground = _foreground(context);
    final TextTheme text = Theme.of(context).textTheme;
    final AppIconData? leading = icon;
    final AppIconData? trailing = trailingIcon ?? (selected && leading == null ? AppIcons.check : null);
    final String? second = detail;
    return Pressable(
      semanticLabel: semanticLabel ?? <String?>[label, second].whereType<String>().join(', '),
      selected: selected ? true : null,
      onPressed: onPressed,
      builder: (BuildContext context, bool _) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget, minWidth: HisaabSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.m, vertical: HisaabSpacing.xs),
        decoration: ShapeDecoration(
          color: _fill(context),
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

  // why: chips are fill-only (D88). At rest a chip is hairline, a clear step darker than the page it
  // sits on (D89); a pick fills ink2, the heaviest chip in the row, so it reads as chosen without
  // relying on the check (D89). Pressable's shrink shows a press. A disabled chip has no fill.
  Color? _fill(BuildContext context) {
    if (onPressed == null) {
      return null;
    }
    return selected ? context.colors.ink2 : context.colors.hairline;
  }

  Color _foreground(BuildContext context) {
    if (onPressed == null) {
      return context.colors.ink2;
    }
    return selected ? context.colors.background : context.colors.ink;
  }
}
