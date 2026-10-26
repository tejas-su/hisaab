import 'package:flutter/material.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// An outlined chip: quick-add amounts, the date and note chips, onboarding choices.
///
/// [selected] fills it with ink. [detail] adds a second, quieter line (e.g. an added bill).
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
  final VoidCallback onPressed;
  final AppIconData? icon;
  final AppIconData? trailingIcon;
  final String? detail;
  final bool selected;

  /// Fill the available width, for big onboarding choices.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected ? context.colors.background : context.colors.ink;
    final TextTheme text = Theme.of(context).textTheme;
    final AppIconData? leading = icon;
    final AppIconData? trailing = trailingIcon;
    final String? second = detail;
    return Pressable(
      semanticLabel: semanticLabel ?? <String?>[label, second].whereType<String>().join(', '),
      selected: selected ? true : null,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget, minWidth: HisaabSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.m, vertical: HisaabSpacing.xs),
        decoration: ShapeDecoration(
          color: selected ? context.colors.ink : (pressed ? context.colors.sunk : null),
          shape: HisaabShapes.squircle(
            HisaabRadii.chip,
            side: BorderSide(color: selected ? context.colors.ink : context.colors.hairline, width: 1.5),
          ),
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
                    Text(second, style: text.bodySmall?.copyWith(color: selected ? context.colors.background : context.colors.ink2)),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[const SizedBox(width: HisaabSpacing.xs), AppIcon(trailing, color: foreground, size: 18)],
          ],
        ),
      ),
    );
  }
}
