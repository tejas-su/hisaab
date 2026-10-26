import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/category_spend.dart';
import 'category_spend_row.dart';
import 'spends_card.dart';

/// *Where it went*: categories by amount, with bars rather than a donut (SPEC FR-SP-4).
///
/// [rows] must be non-empty and biggest first.
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
          ],
        ),
      );
}
