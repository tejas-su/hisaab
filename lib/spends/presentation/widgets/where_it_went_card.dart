import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../domain/entities/category_spend.dart';
import 'category_spend_row.dart';
import 'hatch_key.dart';
import 'spends_card.dart';

/// *Where it went*: categories by amount, with bars rather than a donut (SPEC FR-SP-4).
///
/// [rows] must be non-empty and biggest first. When any row is past its limit, a key under the
/// rows says what the hatch means. The title row ends in *See all*, which calls [onSeeAll] to open
/// every entry of the cycle named by [cycleLabel] (FR-SP-6), so the link stays near the top
/// however many rows there are.
class WhereItWentCard extends StatelessWidget {
  const WhereItWentCard({super.key, required this.rows, required this.cycleLabel, required this.onSeeAll});

  final List<CategorySpend> rows;

  /// The cycle as the switcher names it ("October"), read by TalkBack on *See all*.
  final String cycleLabel;

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => SpendsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(context),
            for (final CategorySpend row in rows)
              CategorySpendRow(key: ValueKey<int>(row.category.id), row: row, biggest: rows.first.spent),
            if (rows.any(_isPastLimit)) ...<Widget>[
              const SizedBox(height: HisaabSpacing.s),
              const HatchKey(key: ValueKey<String>('hatch-key')),
            ],
          ],
        ),
      );

  Widget _header(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(child: Semantics(header: true, child: Text(strings.whereItWent, style: text.titleLarge))),
        const SizedBox(width: HisaabSpacing.m),
        Semantics(
          label: strings.everyEntryIn(cycleLabel),
          button: true,
          excludeSemantics: true,
          child: TextButton(
            key: const ValueKey<String>('see-every-entry'),
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: context.colors.ink,
              minimumSize: const Size(HisaabSizes.minTouchTarget, HisaabSizes.minTouchTarget),
              // why: no inset, so the label ends on the rows' content edge, as Home's See all does.
              padding: EdgeInsetsDirectional.zero,
              // why: the label is narrower than the 48dp target; centred, it would end short of the edge.
              alignment: AlignmentDirectional.centerEnd,
            ),
            child: Text(strings.seeAll, style: text.labelLarge?.copyWith(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  static bool _isPastLimit(CategorySpend row) => row.category.limit.match(() => false, (Money limit) => row.spent > limit);
}
