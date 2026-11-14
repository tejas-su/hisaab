import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_detail.dart';
import '../../domain/entities/category_spend.dart';
import '../spends_graph_copy.dart';
import 'category_detail_panel.dart';
import 'category_spend_row.dart';

/// A row of *Where it went* that opens (SPEC FR-SP-4 AC-R2): the row and a caret as one button
/// with an expanded state, and when [open] the [CategoryDetailPanel] under it. TalkBack reads the
/// row's sentence, then the change while open.
class OpenableSpendRow extends StatelessWidget {
  const OpenableSpendRow({
    super.key,
    required this.row,
    required this.biggest,
    required this.detail,
    required this.change,
    required this.open,
    required this.onToggle,
    required this.onSeeAll,
  });

  final CategorySpend row;
  final CategorySpend biggest;
  final CategoryDetail detail;
  final ComparisonWords? change;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onSeeAll;

  /// From this text scale up, the icon wells drop so the name keeps its width (AC-R2).
  static const double _wellsDropAt = 1.3;
  static const double _halfTurn = 0.5;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String name = row.category.labelIn(strings);
    final bool wells = MediaQuery.textScalerOf(context).scale(1) < _wellsDropAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MergeSemantics(
          child: Semantics(
            button: true,
            expanded: open,
            hint: open ? strings.spendsRowCloseHint : strings.spendsRowOpenHint,
            child: InkWell(
              onTap: onToggle,
              focusColor: context.colors.clear,
              child: Row(
                children: <Widget>[
                  Expanded(child: CategorySpendRow(row: row, biggest: biggest.spent, showWell: wells)),
                  const SizedBox(width: HisaabSpacing.s),
                  AnimatedRotation(
                    turns: open ? _halfTurn : 0,
                    duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.press,
                    child: AppIcon(AppIcons.dropdown, size: 18, color: context.colors.ink2),
                  ),
                  if (open && change != null) Semantics(label: change?.spoken),
                ],
              ),
            ),
          ),
        ),
        if (open)
          CategoryDetailPanel(
            key: ValueKey<String>('detail-${row.category.id}'),
            detail: detail,
            categoryName: name,
            change: change,
            onSeeAll: onSeeAll,
          ),
      ],
    );
  }
}
