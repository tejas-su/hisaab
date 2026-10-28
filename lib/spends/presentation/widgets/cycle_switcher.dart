import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// `‹ October ›`: steps Spends between cycles (SPEC FR-SP-1). A null callback disables its arrow.
class CycleSwitcher extends StatelessWidget {
  const CycleSwitcher({super.key, required this.label, required this.onEarlier, required this.onLater});

  final String label;
  final VoidCallback? onEarlier;
  final VoidCallback? onLater;

  // why: keeps the switcher beside the title on a 320dp phone at 2× text; the label shrinks.
  static const double _maxLabelWidth = 160;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(2),
      decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _arrow(context, const ValueKey<String>('earlier-cycle'), AppIcons.back, strings.earlierCycle, onEarlier),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15)),
            ),
          ),
          _arrow(context, const ValueKey<String>('later-cycle'), AppIcons.next, strings.laterCycle, onLater),
        ],
      ),
    );
  }

  Widget _arrow(BuildContext context, Key key, AppIconData icon, String label, VoidCallback? onPressed) => Pressable(
        key: key,
        semanticLabel: label,
        onPressed: onPressed,
        builder: (BuildContext context, bool pressed) => Container(
          width: HisaabSizes.minTouchTarget,
          height: HisaabSizes.minTouchTarget,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: pressed ? context.colors.hairline : null,
            shape: HisaabShapes.squircle(HisaabRadii.chip),
          ),
          child: AppIcon(icon, size: 20, color: onPressed == null ? context.colors.hairline : context.colors.ink),
        ),
      );
}
