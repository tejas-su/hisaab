import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The due-soon nudge under the hero, as a tappable `sunk` row: the bill's icon, "Electricity
/// ₹1,200 goes out in 3 days", its date and a chevron. A tap opens the bill's sheet
/// (SPEC FR-HO-3, D118).
class DueSoonRow extends StatelessWidget {
  const DueSoonRow({super.key, required this.bill, required this.onOpenBill});

  final DueSoonBill bill;
  final ValueChanged<RecurringRule> onOpenBill;

  static const double _minHeight = 56;
  static const double _radius = 18;

  // why: the row spans the hero card's width and its well's glyph lands on the card's content
  // inset, so the nudge lines up with the hero and the Today list.
  static const double _startInset = HisaabSpacing.m;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String date = DateFormat('EEE, d MMM', Localizations.localeOf(context).toString())
        .format(DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day));
    return Pressable(
      semanticLabel: strings.billGoesOut(bill.label, strings.spokenAmount(context.money.digits(bill.amount)), bill.daysAway),
      semanticHint: strings.dueSoonOpensBill,
      focusRadius: _radius,
      onPressed: () => onOpenBill(bill.rule),
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsetsDirectional.fromSTEB(_startInset, HisaabSpacing.s, HisaabSpacing.m, HisaabSpacing.s),
        decoration: ShapeDecoration(
          color: pressed ? context.colors.hairline : context.colors.sunk,
          shape: HisaabShapes.squircle(_radius),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: HisaabSizes.iconWell,
              height: HisaabSizes.iconWell,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.chip)),
              child: AppIcon(bill.rule.shownIcon.glyph),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.billGoesOut(bill.label, context.money.format(bill.amount), bill.daysAway), style: text.bodyMedium),
                  Text(date, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: HisaabSpacing.s),
            AppIcon(AppIcons.next, size: 18, color: context.colors.ink2),
          ],
        ),
      ),
    );
  }
}
