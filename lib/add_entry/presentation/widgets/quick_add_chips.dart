import 'package:flutter/material.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';

/// +₹10 +₹20 +₹50 +₹100 +₹500: chips that add to the amount, like counting notes (FR-AD-1).
class QuickAddChips extends StatelessWidget {
  const QuickAddChips({super.key, required this.onAdd});

  final ValueChanged<int> onAdd;

  static const List<int> amounts = <int>[10, 20, 50, 100, 500];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        for (final (int index, int rupees) in amounts.indexed) ...<Widget>[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: HisaabChip(
              key: ValueKey<String>('quick-$rupees'),
              label: strings.quickAdd(context.money.format(Money.fromMajor(rupees))),
              semanticLabel: strings.quickAddSpoken(strings.spokenAmount('$rupees')),
              onPressed: () => onAdd(rupees),
            ),
          ),
        ],
      ],
    );
  }
}
