import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/insight.dart';
import 'insight_tile.dart';
import 'spends_card.dart';

/// *Worth knowing*: at most 3 insights, each with one next step (SPEC FR-SP-5). [previousCycle]
/// names the cycle before the one shown, for the insights that compare with it.
class InsightsCard extends StatelessWidget {
  const InsightsCard({
    super.key,
    required this.insights,
    required this.categories,
    required this.previousCycle,
    required this.onSeeEntries,
    required this.onUseLimits,
    required this.limitsFailed,
  });

  final List<Insight> insights;
  final Map<int, Category> categories;
  final String previousCycle;
  final ValueChanged<int> onSeeEntries;
  final ValueChanged<LimitOffer> onUseLimits;
  final bool limitsFailed;

  @override
  Widget build(BuildContext context) => SpendsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(AppLocalizations.of(context).tipsTitle, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final (int index, Insight insight) in insights.indexed) ...<Widget>[
              if (index > 0) Divider(height: HisaabSpacing.xl, color: context.colors.hairline) else const SizedBox(height: HisaabSpacing.m),
              InsightTile(
                key: ValueKey<int>(index),
                insight: insight,
                categories: categories,
                previousCycle: previousCycle,
                onSeeEntries: onSeeEntries,
                onUseLimits: onUseLimits,
                limitsFailed: limitsFailed,
              ),
            ],
          ],
        ),
      );
}
