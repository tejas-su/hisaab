import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The *Can I afford it?* card beside Ask AI on Spends (SPEC FR-SP-9 AC-1, UI_DESIGN 5.4a): the
/// same borderless near-white card as the Ask AI card, with "Check a big buy" under the title and
/// one button for TalkBack. [onPressed] opens the check.
///
/// Its well is `sunk` with an ink glyph, never marigold: the marigold well is Ask AI's handoff
/// (D66), and the act inside the sheet carries the signal key.
class AffordCard extends StatelessWidget {
  const AffordCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    return Pressable(
      semanticLabel: strings.spokenPair(strings.affordTitle, strings.affordCardNote),
      onPressed: onPressed,
      focusRadius: HisaabRadii.card,
      builder: (BuildContext context, bool pressed) => Container(
        key: const ValueKey<String>('afford-card-surface'),
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
        decoration: ShapeDecoration(
          color: pressed ? context.colors.sunk : context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.card),
        ),
        child: Row(
          children: <Widget>[
            Container(
              key: const ValueKey<String>('afford-card-well'),
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              // why: pressed, the card itself turns sunk; the well swaps so the glyph stays framed.
              decoration: ShapeDecoration(
                color: pressed ? context.colors.surface : context.colors.sunk,
                shape: HisaabShapes.squircle(HisaabRadii.chip),
              ),
              child: AppIcon(AppIcons.questionLine, color: context.colors.ink),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.affordTitle, style: type.bodyLarge),
                  Text(strings.affordCardNote, style: type.bodySmall?.copyWith(color: context.colors.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
