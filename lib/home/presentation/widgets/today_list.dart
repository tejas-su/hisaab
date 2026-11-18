import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import 'home_heading_focus.dart';
import 'today_row_reveal.dart';

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
    this.justFixed = const Option<int>.none(),
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

  /// The id of a fix's row that just appeared; it grows in after the hero has rolled (FR-FX-5 AC-2).
  final Option<int> justFixed;

  // why: focus lands on the heading when the missed-log line that opened a tray goes (FR-HO-3);
  // it takes no focus of its own in traversal, and none at all when no node is offered.
  static Widget _heading(BuildContext context, Widget heading) {
    final FocusNode? node = HomeHeadingFocus.maybeOf(context);
    return node == null ? heading : Focus(focusNode: node, skipTraversal: true, child: heading);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsetsDirectional.only(top: 6, bottom: HisaabSpacing.s),
      // why: a swiped row and its Delete background would otherwise slide past the card's corners.
      clipBehavior: Clip.antiAlias,
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
                _heading(context, Semantics(header: true, child: Text(strings.todayList, style: text.titleLarge))),
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
            TodayRowReveal(
              key: ValueKey<String>('today-row-${entry.id}'),
              delayed: justFixed.match(() => false, (int id) => id == entry.id),
              child: EntryRow(
                key: ValueKey<int>(entry.id),
                entry: entry,
                category: categories[entry.categoryId],
                billName: billNames[entry.recurringId],
                onEdit: () => onEdit(entry),
                onDelete: () => onDelete(entry),
                onThresholdReached: onThresholdReached,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
