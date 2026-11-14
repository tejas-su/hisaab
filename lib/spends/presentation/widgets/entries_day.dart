import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// One day of *Every entry*: "Mon, 26 Oct", what was spent that day, and its rows (FR-SP-6).
class EntriesDay extends StatelessWidget {
  const EntriesDay({
    super.key,
    required this.day,
    required this.entries,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
  });

  final CalendarDate day;
  final List<Entry> entries;
  final Map<int, Category> categories;
  final ValueChanged<Entry> onEdit;
  final ValueChanged<Entry> onDelete;
  final VoidCallback onThresholdReached;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Money spent = entries
        .where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged)
        .fold(Money.zero, (Money total, Entry e) => total + e.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.l, HisaabSpacing.gutter, HisaabSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  DateFormat('EEE, d MMM', context.money.locale).format(DateTime(day.year, day.month, day.day)),
                  style: text.titleMedium,
                ),
              ),
              const SizedBox(width: 10),
              Text(context.money.format(spent), style: text.labelLarge?.copyWith(color: context.colors.ink2)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.xs),
          // why: a swiped row and its Delete background would otherwise slide past the card's corners.
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (int index, Entry entry) in entries.indexed) ...<Widget>[
                if (index > 0) Divider(indent: 74, endIndent: HisaabSpacing.gutter, color: context.colors.hairline),
                EntryRow(
                  key: ValueKey<int>(entry.id),
                  entry: entry,
                  category: categories[entry.categoryId],
                  onEdit: () => onEdit(entry),
                  onDelete: () => onDelete(entry),
                  onThresholdReached: onThresholdReached,
                  showUsedDetail: true,
                  showNotLoggedDetail: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
