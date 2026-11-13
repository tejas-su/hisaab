import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/focus_ring.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_glyph.dart';

/// One bill or saving: its name, its day of the month and its amount, "about" when it changes (SPEC FR-SE-1, D123).
/// A saving with money set aside adds a third line, "{amount} set aside" (AC-Y3).
///
/// It leads with the bill's icon (D118). Tap opens the bill sheet; swiping left deletes it at once (Undo comes from the page). TalkBack gets a
/// Delete action, since swiping is gesture-only.
class BillRow extends StatelessWidget {
  const BillRow({
    super.key,
    required this.bill,
    required this.onEdit,
    required this.onDelete,
    required this.onThresholdReached,
    this.setAside,
  });

  final RecurringRule bill;

  /// What this saving has set aside; the third line shows only when it is above ₹0.
  final Money? setAside;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// The swipe crossed the delete threshold (for the haptic).
  final VoidCallback onThresholdReached;

  @override
  Widget build(BuildContext context) {
    final String delete = AppLocalizations.of(context).delete;
    return Dismissible(
      key: ValueKey<int>(bill.id),
      direction: DismissDirection.endToStart,
      onUpdate: (DismissUpdateDetails details) {
        if (details.reached && !details.previousReached) {
          onThresholdReached();
        }
      },
      onDismissed: (DismissDirection _) => onDelete(),
      background: Container(
        color: context.colors.sunk,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: HisaabSpacing.gutter),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppIcon(AppIcons.delete),
            const SizedBox(width: HisaabSpacing.s),
            Text(delete, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
      child: Semantics(
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{CustomSemanticsAction(label: delete): onDelete},
        child: FocusRing(
          // why: rows fill a clipping card, so the ring is drawn inside the row; its outer corner
          // matches the card's (D99).
          radius: HisaabRadii.card - FocusRing.outset,
          inset: const EdgeInsets.all(FocusRing.outset),
          child: InkWell(onTap: onEdit, focusColor: context.colors.clear, child: _content(context)),
        ),
      ),
    );
  }

  Money? get _shownSetAside {
    final Money? aside = setAside;
    return aside != null && aside > Money.zero ? aside : null;
  }

  // why: a changing or card bill's amount is only the estimate, so it says "about" (D123).
  String _estimated(AppLocalizations strings, String amount) =>
      bill.amountMode == AmountMode.fixed ? amount : strings.billAmountAbout(amount);

  Widget _content(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final String when = strings.billEveryMonth(bill.schedule.anchor.day);
    final Money? aside = _shownSetAside;
    final String schedule = strings.billRowSpoken(bill.label, _estimated(strings, strings.spokenAmount(context.money.digits(bill.amount))), when);
    final String spoken = aside == null
        ? schedule
        : strings.spokenPair(schedule, strings.savingSetAside(strings.spokenAmount(context.money.digits(aside))));
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: 9),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(14)),
              child: AppIcon(bill.glyph),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(bill.label, style: text.bodyLarge),
                  Text(when, style: text.bodySmall?.copyWith(fontSize: 14)),
                  if (aside != null)
                    Text(
                      strings.savingSetAside(context.money.format(aside)),
                      key: const ValueKey<String>('set-aside'),
                      style: text.bodySmall?.copyWith(fontSize: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(width: HisaabSpacing.s),
            Text(_estimated(strings, context.money.format(bill.amount)), style: HisaabType.rowAmount(context.colors.ink)),
          ],
        ),
      ),
    );
  }
}
