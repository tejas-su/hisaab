import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_detail.dart';
import '../month_story_copy.dart';
import '../spends_graph_copy.dart';
import 'comparison_line.dart';

/// What an opened row of *Where it went* shows (SPEC FR-SP-4 AC-R2): its [change] when there is
/// one, a caption, up to 3 entries and, past 3, *See {Cat} entries*.
class CategoryDetailPanel extends StatelessWidget {
  const CategoryDetailPanel({super.key, required this.detail, required this.categoryName, required this.change, required this.onSeeAll});

  final CategoryDetail detail;
  final String categoryName;
  final ComparisonWords? change;
  final VoidCallback? onSeeAll;

  /// Lines the panel up with the row's name: the icon well and its gap.
  static const double indent = 46;
  static const int _shownEntries = 3;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final VoidCallback? seeAll = onSeeAll;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: indent, bottom: HisaabSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (change case final ComparisonWords words) ...<Widget>[
            ComparisonLine(words: words, small: true),
            const SizedBox(height: HisaabSpacing.s),
          ],
          Text(_caption(strings), style: type.labelSmall),
          const SizedBox(height: HisaabSpacing.xs),
          for (final Entry entry in detail.top) _entry(context, strings, entry),
          if (seeAll != null && detail.count > _shownEntries)
            TextButton(
              key: const ValueKey<String>('see-category-entries'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, HisaabSizes.minTouchTarget)),
              onPressed: seeAll,
              child: Text(strings.seeEntries(categoryName), style: type.labelLarge),
            ),
        ],
      ),
    );
  }

  String _caption(AppLocalizations strings) =>
      detail.count == _shownEntries ? strings.spendsTopCaptionAllThree : strings.spendsTopCaption(detail.count);

  Widget _entry(BuildContext context, AppLocalizations strings, Entry entry) {
    final TextTheme type = Theme.of(context).textTheme;
    final String locale = Localizations.localeOf(context).toString();
    final String? note = entry.note?.trim();
    final bool hasNote = note != null && note.isNotEmpty;
    final String label = hasNote ? note : strings.spendsTopNoNote;
    final String date = MonthStoryCopy.shortDate(entry.date, locale);
    return Semantics(
      container: true,
      label: strings.spendsTopEntrySpoken(label, date, strings.spokenAmount(context.money.digits(entry.amount))),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.xs),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: label, style: hasNote ? type.bodyMedium : type.bodyMedium?.copyWith(color: context.colors.ink2)),
                    TextSpan(text: '${strings.separator}$date', style: type.bodySmall),
                  ],
                ),
              ),
            ),
            Text(context.money.format(entry.amount), style: HisaabType.rowAmount(context.colors.ink).copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
