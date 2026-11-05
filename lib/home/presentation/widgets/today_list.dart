import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// Today's latest entries with the day's total and *See all*, or the empty sentence (SPEC FR-HO-4).
///
/// [onSeeAll] opens every entry of the cycle; *See all* is hidden when it is null.
class TodayList extends StatelessWidget {
  const TodayList({
    super.key,
    required this.entries,
    required this.categories,
    required this.spentToday,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
    this.onSeeAll,
    this.billNames = const <int, String>{},
  });

  final List<Entry> entries;
  final Map<int, Category> categories;
  final Money spentToday;
  final ValueChanged<Entry> onEdit;
  final ValueChanged<Entry> onDelete;
  final VoidCallback onThresholdReached;
  final VoidCallback? onSeeAll;

  /// Each bill rule's name by id, so a row a bill posted names it.
  final Map<int, String> billNames;

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
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Semantics(header: true, child: Text(strings.todayList, style: text.titleLarge)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.money.format(spentToday), style: text.labelLarge?.copyWith(color: context.colors.ink2, fontSize: 15)),
                ),
                if (onSeeAll case final VoidCallback seeAll)
                  TextButton(
                    key: const ValueKey<String>('see-all'),
                    onPressed: seeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.ink,
                      minimumSize: const Size(HisaabSizes.minTouchTarget, HisaabSizes.minTouchTarget),
                      // why: no inset, so the label ends on the cards' content edge.
                      padding: EdgeInsetsDirectional.zero,
                    ),
                    child: Text(strings.seeAll, style: text.labelLarge?.copyWith(fontSize: 15)),
                  ),
              ],
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.xs, HisaabSpacing.gutter, HisaabSpacing.m),
              child: Text(strings.emptyToday, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
            ),
          for (final (int index, Entry entry) in entries.indexed) ...<Widget>[
            if (index > 0) Divider(indent: 74, endIndent: HisaabSpacing.gutter, color: context.colors.hairline),
            EntryRow(
              key: ValueKey<int>(entry.id),
              entry: entry,
              category: categories[entry.categoryId],
              billName: billNames[entry.recurringId],
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
