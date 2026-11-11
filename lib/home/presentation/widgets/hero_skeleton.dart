import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/display_card.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The hero card's shape while Home loads: the label, no number, no spinner over amounts. Raised
/// and etched like the hero, so nothing jumps when the numbers arrive (D106).
class HeroSkeleton extends StatelessWidget {
  const HeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) => DisplayCard(
    raised: true,
    etched: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context).safeToSpendToday,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2),
        ),
        const SizedBox(height: HisaabSpacing.l),
        Container(
          height: 40,
          decoration: BoxDecoration(color: context.colors.blockIdle, borderRadius: BorderRadius.circular(HisaabRadii.block)),
        ),
      ],
    ),
  );
}
