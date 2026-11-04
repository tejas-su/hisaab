import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../domain/entities/category_spend.dart';
import 'category_spend_row.dart';
import 'hatch_key.dart';
import 'spends_card.dart';

/// *Where it went*: categories by amount, with bars rather than a donut (SPEC FR-SP-4).
///
/// [rows] must be non-empty and biggest first. When any row is past its limit, a key under the
/// rows says what the hatch means.
class WhereItWentCard extends StatelessWidget {
  const WhereItWentCard({super.key, required this.rows});

  final List<CategorySpend> rows;

  @override
  Widget build(BuildContext context) => SpendsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(AppLocalizations.of(context).whereItWent, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 6),
            for (final CategorySpend row in rows)
              CategorySpendRow(key: ValueKey<int>(row.category.id), row: row, biggest: rows.first.spent),
            if (rows.any(_isPastLimit)) ...<Widget>[
              const SizedBox(height: HisaabSpacing.s),
              const HatchKey(key: ValueKey<String>('hatch-key')),
            ],
          ],
        ),
      );

  static bool _isPastLimit(CategorySpend row) => row.category.limit.match(() => false, (Money limit) => row.spent > limit);
}
