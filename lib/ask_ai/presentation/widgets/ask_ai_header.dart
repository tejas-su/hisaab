import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The Ask AI title row with Back, whose 40dp well sits flush with the content edge (D57).
class AskAiHeader extends StatelessWidget {
  const AskAiHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        // why: without its own container, Back merges with the title into one node and TalkBack
        // reads "Back Ask AI" as one heading button.
        Semantics(
          container: true,
          child: Pressable(
            key: const ValueKey<String>('ask-ai-back'),
            semanticLabel: strings.back,
            onPressed: () => Navigator.of(context).maybePop(),
            builder: (BuildContext context, bool pressed) => Container(
              width: HisaabSizes.minTouchTarget,
              height: HisaabSizes.minTouchTarget,
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: HisaabSizes.iconWell,
                height: HisaabSizes.iconWell,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: pressed ? context.colors.hairline : context.colors.sunk,
                  shape: HisaabShapes.squircle(HisaabRadii.chip),
                ),
                child: const AppIcon(AppIcons.back),
              ),
            ),
          ),
        ),
        const SizedBox(width: HisaabSpacing.s),
        Expanded(
          child: Semantics(
            container: true,
            header: true,
            child: Text(strings.askAiTitle, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
      ],
    );
  }
}
