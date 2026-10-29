import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The Ask AI card at the top of Spends (SPEC FR-SP-2): a near-white card with no border, like
/// every card (D45), and a marigold well, since handing off to an AI is an act (UI_DESIGN §5.4).
/// A title names [cycleLabel], the cycle shown; a quieter note below says the prompt is
/// previewed before it is shared (D70).
class AskAiCard extends StatelessWidget {
  const AskAiCard({super.key, required this.cycleLabel, required this.onPressed});

  final String cycleLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final String title = strings.askAiCardTitle(cycleLabel);
    return Pressable(
      semanticLabel: strings.spokenPair(title, strings.askAiCardNote),
      onPressed: onPressed,
      focusRadius: HisaabRadii.card,
      builder: (BuildContext context, bool pressed) => Container(
        key: const ValueKey<String>('ask-ai-card-surface'),
        padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
        decoration: ShapeDecoration(
          color: pressed ? context.colors.sunk : context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.card),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: type.bodyLarge),
                  Text(strings.askAiCardNote, style: type.bodySmall?.copyWith(color: context.colors.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
