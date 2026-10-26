import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// One Settings entry: an icon well, its [label] and an arrow; tapping it opens [onTap]'s page.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.label, required this.onTap});

  final AppIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.m),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
                child: AppIcon(icon),
              ),
              const SizedBox(width: HisaabSpacing.m),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              AppIcon(AppIcons.next, color: context.colors.ink2),
            ],
          ),
        ),
      );
}
