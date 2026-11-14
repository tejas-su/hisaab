import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_detail.dart';
import '../../domain/entities/category_spend.dart';
import '../spends_graph_copy.dart';
import 'category_spend_row.dart';
import 'hatch_key.dart';
import 'openable_spend_row.dart';
import 'see_every_entry_button.dart';
import 'spends_card.dart';

/// *Where it went*: categories by amount, with bars rather than a donut (SPEC FR-SP-4).
///
/// [rows] must be non-empty and biggest first. When any row is past its limit, a key under the
/// rows says what the hatch means. The title row ends in *See all*, which calls [onSeeAll] to open
/// every entry of the cycle named by [cycleLabel] (FR-SP-6), so the link stays near the top
/// however many rows there are.
///
/// With [details], a headline names the biggest category and each row opens, one at a time, to
/// its change ([changeOf]), its biggest entries and *See {Cat} entries* ([onSeeCategory]) (AC-R1,
/// AC-R2). Without them the rows are as before.
class WhereItWentCard extends StatefulWidget {
  const WhereItWentCard({
    super.key,
    required this.rows,
    required this.cycleLabel,
    required this.onSeeAll,
    this.details = const <int, CategoryDetail>{},
    this.changeOf,
    this.onSeeCategory,
  });

  final List<CategorySpend> rows;

  /// The cycle as the switcher names it ("October"), read by TalkBack on *See all*.
  final String cycleLabel;

  final VoidCallback onSeeAll;

  /// What each row shows when opened, by category id.
  final Map<int, CategoryDetail> details;

  /// Writes a row's change; null when there is no comparison.
  final ComparisonWords Function(Money change)? changeOf;

  /// Opens the cycle's entries filtered to a category id.
  final ValueChanged<int>? onSeeCategory;

  @override
  State<WhereItWentCard> createState() => _WhereItWentCardState();
}

class _WhereItWentCardState extends State<WhereItWentCard> {
  int? _open;

  @override
  Widget build(BuildContext context) => SpendsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(context),
            if (widget.details.isNotEmpty) _headline(context),
            for (final CategorySpend row in widget.rows) _row(row),
            if (widget.rows.any(_isPastLimit)) ...<Widget>[
              const SizedBox(height: HisaabSpacing.s),
              const HatchKey(key: ValueKey<String>('hatch-key')),
            ],
          ],
        ),
      );

  Widget _row(CategorySpend row) {
    final CategoryDetail? detail = widget.details[row.category.id];
    if (detail == null) {
      return CategorySpendRow(key: ValueKey<int>(row.category.id), row: row, biggest: widget.rows.first.spent);
    }
    final ComparisonWords Function(Money)? changeOf = widget.changeOf;
    return OpenableSpendRow(
      key: ValueKey<int>(row.category.id),
      row: row,
      biggest: widget.rows.first,
      detail: detail,
      change: changeOf == null ? null : detail.change.map(changeOf).toNullable(),
      open: _open == row.category.id,
      onToggle: () => setState(() => _open = _open == row.category.id ? null : row.category.id),
      onSeeAll: () => widget.onSeeCategory?.call(row.category.id),
    );
  }

  Widget _header(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(child: Semantics(header: true, child: Text(strings.whereItWent, style: text.titleLarge))),
        const SizedBox(width: HisaabSpacing.m),
        SeeEveryEntryButton(label: strings.seeAll, cycleLabel: widget.cycleLabel, onPressed: widget.onSeeAll),
      ],
    );
  }

  Widget _headline(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String top = widget.rows.first.category.labelIn(strings);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.xs, bottom: HisaabSpacing.s),
      child: Text(
        widget.rows.length == 1 ? strings.spendsWhereHeadlineAll(top) : strings.spendsWhereHeadline(top),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
      ),
    );
  }

  static bool _isPastLimit(CategorySpend row) => row.category.limit.match(() => false, (Money limit) => row.spent > limit);
}
