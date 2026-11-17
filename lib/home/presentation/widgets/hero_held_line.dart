import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The hero tucked into one line while an entry card is open on Home (SPEC FR-AD-8 AC-11): the held
/// figure, and once a change would move it, the figure after Done. Home recomputes only on close.
class HeroHeldLine extends StatelessWidget {
  const HeroHeldLine({super.key, required this.safeToday, this.preview = const Option<Money>.none()});

  /// *Safe to spend today* as it stands, held while the card is open.
  final Money safeToday;

  /// The figure after Done, when the change can be shown before it is written.
  final Option<Money> preview;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String held = context.money.format(safeToday);
    final String spoken = preview.match(
      () => strings.heroHeldSpokenWaiting(held),
      (Money next) => strings.heroHeldSpoken(held, context.money.format(next)),
    );
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Container(
        key: const ValueKey<String>('hero-held'),
        constraints: const BoxConstraints(minHeight: _height),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.s),
        decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
        child: Wrap(
          spacing: HisaabSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(strings.heroHeldTitle, style: text.labelLarge?.copyWith(color: context.colors.ink2)),
            AmountText(safeToday, roll: false, style: text.titleLarge),
            ...preview.match(
              () => <Widget>[Text(strings.heroHeldWaiting, style: text.bodySmall?.copyWith(color: context.colors.ink2))],
              (Money next) => <Widget>[
                Text(strings.heroHeldNext(context.money.format(next)), style: text.titleLarge?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()])),
                Text(strings.heroHeldAfterDone, style: text.bodySmall?.copyWith(color: context.colors.ink2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
