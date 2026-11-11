import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/insight.dart';
import '../insight_copy.dart';

/// One insight: a sentence and its one action (SPEC BR-14, FR-SP-5).
///
/// [previousCycle] names the cycle before the one shown ("September"). [onSeeEntries] opens the entries of a category; [onUseLimits] accepts the limit offer, after
/// which [limitsFailed] shows the save error.
class InsightTile extends StatelessWidget {
  const InsightTile({
    super.key,
    required this.insight,
    required this.categories,
    required this.previousCycle,
    required this.onSeeEntries,
    required this.onUseLimits,
    this.limitsFailed = false,
  });

  final Insight insight;
  final Map<int, Category> categories;
  final String previousCycle;
  final ValueChanged<int> onSeeEntries;
  final ValueChanged<LimitOffer> onUseLimits;
  final bool limitsFailed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final Insight current = insight;
    String categoryName(int id) => categories[id]?.labelIn(strings) ?? strings.categoryName('other');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          InsightCopy.sentence(
            current,
            strings: strings,
            money: context.money,
            categoryName: categoryName,
            previousCycle: previousCycle,
          ),
          style: text.bodyLarge,
        ),
        const SizedBox(height: HisaabSpacing.s),
        HisaabChip(
          label: InsightCopy.action(current, strings, categoryName: categoryName),
          trailingIcon: AppIcons.next,
          onSurface: true,
          onPressed: () => switch (current) {
            LimitOffer() => onUseLimits(current),
            CategoryUp(:final int categoryId) ||
            BiggestSpend(:final int categoryId) ||
            SteadiestCategory(:final int categoryId) =>
              onSeeEntries(categoryId),
          },
        ),
        if (limitsFailed && current is LimitOffer) ...<Widget>[
          const SizedBox(height: HisaabSpacing.xs),
          Text(strings.couldntSave, style: text.bodySmall?.copyWith(color: context.colors.ink)),
        ],
      ],
    );
  }
}
