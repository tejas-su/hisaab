import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The Ask AI card at the top of Spends (SPEC FR-SP-2): an ink outline with a marigold well,
/// since handing off to an AI is an act (UI_DESIGN §5.4). [cycleLabel] names the cycle shown.
class AskAiCard extends StatelessWidget {
  const AskAiCard({super.key, required this.cycleLabel, required this.onPressed});

  final String cycleLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String text = AppLocalizations.of(context).askAiCard(cycleLabel);
    return Pressable(
      semanticLabel: text,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) => Container(
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
        decoration: ShapeDecoration(
          color: pressed ? context.colors.sunk : context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.card, side: BorderSide(color: context.colors.ink, width: 1.5)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              // why: the marigold well carries an ink outline and ink glyph, so the signal colour
              // is never bare on the light background.
              decoration: ShapeDecoration(
                color: context.colors.signal,
                shape: HisaabShapes.squircle(HisaabRadii.chip, side: BorderSide(color: context.colors.onSignal, width: 1.5)),
              ),
              child: AppIcon(AppIcons.askAi, color: context.colors.onSignal),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
