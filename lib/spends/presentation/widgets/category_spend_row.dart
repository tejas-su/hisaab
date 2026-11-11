import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_spend.dart';
import 'limit_bar_painter.dart';

/// One *Where it went* row: icon well, name, share, amount and a bar sized against [biggest]
/// (SPEC FR-SP-4). With a limit the name carries "₹200 left", and past it "₹840 past limit"
/// replaces the share (BR-12).
class CategorySpendRow extends StatelessWidget {
  const CategorySpendRow({super.key, required this.row, required this.biggest});

  final CategorySpend row;

  /// The biggest category's spend; its bar is full width.
  final Money biggest;

  static const double _wellSize = 36;
  static const double _barArea = 12;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final Money? limit = row.category.limit.toNullable();
    final Money? past = limit != null && row.spent > limit ? row.spent - limit : null;
    final String name = row.category.labelIn(strings);
    final String? detail = limit == null ? null : _limitWords(strings, limit, context.money.format);
    return Semantics(
      container: true,
      label: _spoken(context, strings, name, limit),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: _wellSize,
                  height: _wellSize,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.chip)),
                  child: AppIcon(AppIcons.forKey(row.category.iconKey), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: name,
                      children: <InlineSpan>[
                        if (detail != null)
                          TextSpan(
                            text: '${strings.separator}$detail',
                            style: text.bodyMedium?.copyWith(color: context.colors.ink2),
                          ),
                      ],
                    ),
                    style: text.bodyLarge,
                  ),
                ),
                if (past == null) ...<Widget>[
                  Text(strings.percentShare(row.percent), style: text.bodySmall),
                  const SizedBox(width: HisaabSpacing.s),
                ],
                Text(context.money.format(row.spent), style: HisaabType.rowAmount(context.colors.ink)),
              ],
            ),
            const SizedBox(height: HisaabSpacing.xs),
            SizedBox(
              height: _barArea,
              width: double.infinity,
              child: CustomPaint(painter: _painter(context, limit)),
            ),
          ],
        ),
      ),
    );
  }

  LimitBarPainter _painter(BuildContext context, Money? limit) {
    final double? limitAt = limit == null ? null : limit.amountMinor / biggest.amountMinor;
    return LimitBarPainter(
      fill: row.spent.amountMinor / biggest.amountMinor,
      // why: a limit beyond the biggest bar would sit off the end, so no tick is drawn (BR-12).
      limitAt: limitAt != null && limitAt < 1 ? limitAt : null,
      ink: context.colors.ink,
      track: context.colors.sunk,
      notch: context.colors.surface,
      tick: context.colors.ink2,
    );
  }

  /// "₹840 past limit" once over, otherwise "₹200 left" (₹0 at the limit exactly), with each
  /// amount written by [amount].
  String _limitWords(AppLocalizations strings, Money limit, String Function(Money) amount) =>
      row.spent > limit ? strings.pastLimit(amount(row.spent - limit)) : strings.limitLeft(amount(limit - row.spent));

  String _spoken(BuildContext context, AppLocalizations strings, String name, Money? limit) {
    String amount(Money money) => strings.spokenAmount(context.money.digits(money));
    return <String>[
      if (limit != null) ...<String>[strings.limitOf(amount(limit)), _limitWords(strings, limit, amount)],
    ].fold(strings.categoryRowSpoken(name, amount(row.spent), row.percent), strings.spokenPair);
  }
}
