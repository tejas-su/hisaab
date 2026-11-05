import 'package:flutter/material.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';

/// One quiet line above *Where it went*: "Spent ₹27,570 · Saved ₹5,000" for the cycle shown, so
/// saving is seen beside spending without ever counting as it (D120). Show it only when the cycle
/// has saves.
class SpentSavedLine extends StatelessWidget {
  const SpentSavedLine({super.key, required this.spent, required this.saved});

  final Money spent;
  final Money saved;

  @override
  Widget build(BuildContext context) => Text(
        AppLocalizations.of(context).spentAndSaved(context.money.format(spent), context.money.format(saved)),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
      );
}
