import 'package:flutter/material.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// An outlined chip: quick-add amounts, the date and note chips, onboarding choices.
///
/// [selected] raises it as a surface pill with an ink edge and a trailing check in light theme,
/// and fills it with ink in dark (D85). [detail] adds a second, quieter line (e.g. an added bill).
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
    // why: an ink slab outweighed the marigold key beside it, so in light theme a pick is a
    // raised surface pill marked by its ink edge and a check (D85); in dark, where surface is
    // darker than the page, it stays an ink pill, as the Spent | Got switch does (D47).
    final bool inkPick = selected && Theme.of(context).brightness == Brightness.dark;
    final Color foreground = inkPick
        ? context.colors.background
        : (onPressed == null ? context.colors.ink2 : context.colors.ink);
    final TextTheme text = Theme.of(context).textTheme;
    final AppIconData? leading = icon;
    final AppIconData? trailing = trailingIcon ?? (selected && !inkPick && leading == null ? AppIcons.check : null);
    final String? second = detail;
    return Pressable(
      semanticLabel: semanticLabel ?? <String?>[label, second].whereType<String>().join(', '),
      selected: selected ? true : null,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget, minWidth: HisaabSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.m, vertical: HisaabSpacing.xs),
        decoration: ShapeDecoration(
          color: selected ? (inkPick ? context.colors.ink : context.colors.surface) : (pressed ? context.colors.sunk : null),
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
                    Text(second, style: text.bodySmall?.copyWith(color: inkPick ? context.colors.background : context.colors.ink2)),
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
