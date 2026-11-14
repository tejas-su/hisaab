import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The one-time install line in Home's nudge slot, as a tappable `sunk` row: "Already spent some
/// this month?" over "Fix my number" and a chevron (SPEC FR-HO-3, FR-FX-1). A tap opens the
/// *Fix my number* sheet. It shows no amount, has no ×, and is never marigold.
///
/// [period] is `week` for a weekly cycle, otherwise `month`.
class InstallLineRow extends StatelessWidget {
  const InstallLineRow({super.key, required this.period, required this.onTap});

  final String period;
  final VoidCallback onTap;

  static const double _minHeight = 56;
  static const double _radius = 18;

  // why: the row spans the hero card's width and its well's glyph lands on the card's content
  // inset, as the due-soon row's does.
  static const double _startInset = HisaabSpacing.m;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String title = strings.fixInstallTitle(period);
    return Pressable(
      semanticLabel: '$title ${strings.fixMyNumber}',
      semanticHint: strings.waitingOpensHint,
      focusRadius: _radius,
      onPressed: onTap,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsetsDirectional.fromSTEB(_startInset, HisaabSpacing.s, HisaabSpacing.m, HisaabSpacing.s),
        decoration: ShapeDecoration(color: pressed ? context.colors.hairline : context.colors.sunk, shape: HisaabShapes.squircle(_radius)),
        child: Row(
          children: <Widget>[
            Container(
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.chip)),
              child: const AppIcon(AppIcons.fixMyNumber),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: text.bodyMedium),
                  Text(strings.fixMyNumber, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: HisaabSpacing.s),
            AppIcon(AppIcons.next, size: 18, color: context.colors.ink2),
          ],
        ),
      ),
    );
  }
}
