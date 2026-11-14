import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The slim row on days 1 to 7 of a new cycle: "**September is done.** See your month ›" (SPEC
/// FR-SP-7 AC-2). It opens the cycle before's story; one button for TalkBack.
class MonthStoryRow extends StatelessWidget {
  const MonthStoryRow({super.key, required this.previousLabel, required this.onPressed});

  /// The finished cycle, named as the switcher names it.
  final String previousLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? body = Theme.of(context).textTheme.bodyMedium;
    final String done = strings.storyRowDone(previousLabel);
    return Pressable(
      semanticLabel: '$done ${strings.storyRowAction}',
      onPressed: onPressed,
      focusRadius: HisaabRadii.tile,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget + HisaabSpacing.s),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.m),
        decoration: ShapeDecoration(
          color: pressed ? context.colors.sunk : context.colors.surface,
          shape: HisaabShapes.squircle(HisaabRadii.tile),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: done, style: HisaabType.emphasized(body)),
                    TextSpan(text: ' ${strings.storyRowAction}', style: body),
                  ],
                ),
              ),
            ),
            AppIcon(AppIcons.next, color: context.colors.ink2),
          ],
        ),
      ),
    );
  }
}
