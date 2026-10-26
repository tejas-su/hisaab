import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import 'today_row.dart';

/// Today's latest entries with the day's total, or the empty sentence (SPEC FR-HO-4).
class TodayList extends StatelessWidget {
  const TodayList({
    super.key,
    required this.entries,
    required this.categories,
    required this.spentToday,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
  });

  final List<Entry> entries;
  final Map<int, Category> categories;
  final Money spentToday;
  final ValueChanged<Entry> onEdit;
  final ValueChanged<Entry> onDelete;
  final VoidCallback onThresholdReached;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsetsDirectional.only(top: 6, bottom: HisaabSpacing.s),
      decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, HisaabSpacing.s, 18, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Semantics(header: true, child: Text(strings.todayList, style: text.titleLarge)),
                const SizedBox(width: 10),
                Text(context.money.format(spentToday), style: text.labelLarge?.copyWith(color: context.colors.ink2, fontSize: 15)),
              ],
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, HisaabSpacing.xs, 18, HisaabSpacing.m),
              child: Text(strings.emptyToday, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
            ),
          for (final (int index, Entry entry) in entries.indexed) ...<Widget>[
            if (index > 0) Divider(indent: 72, endIndent: 18, color: context.colors.hairline),
            TodayRow(
              key: ValueKey<int>(entry.id),
              entry: entry,
              category: categories[entry.categoryId],
              onEdit: () => onEdit(entry),
              onDelete: () => onDelete(entry),
              onThresholdReached: onThresholdReached,
            ),
          ],
        ],
      ),
    );
  }
}
