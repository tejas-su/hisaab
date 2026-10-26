import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The one-line nudge under the hero: "Electricity ₹1,200 goes out in 3 days" (SPEC FR-HO-3).
class DueSoonNote extends StatelessWidget {
  const DueSoonNote({super.key, required this.bill});

  final DueSoonBill bill;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String spoken = strings.billGoesOut(bill.label, strings.spokenAmount(context.money.digits(bill.amount)), bill.daysAway);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: AppIcon(AppIcons.info, size: 18, color: context.colors.ink2),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(
            child: Text(
              strings.billGoesOut(bill.label, context.money.format(bill.amount), bill.daysAway),
              semanticsLabel: spoken,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
