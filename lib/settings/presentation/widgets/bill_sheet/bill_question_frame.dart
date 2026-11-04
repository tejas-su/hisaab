import 'package:flutter/material.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/hisaab_back_button.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import 'bill_head.dart';
import 'bill_slip.dart';

/// One question inside the bill sheet: Back and the [question], a compact slip with the
/// bill's [name], [icon], [figure] and [caption], then the question's [body] (SPEC FR-SE-1 AC-3).
///
/// Back returns to the bill through the sheet's `PopScope`. When [saveFailed], "Couldn't save.
/// Try again." shows under the slip (AC-7).
class BillQuestionFrame extends StatelessWidget {
  const BillQuestionFrame({
    super.key,
    required this.question,
    required this.name,
    required this.icon,
    required this.figure,
    required this.caption,
    required this.body,
    this.saveFailed = false,
  });

  final String question;
  final String name;
  final BillIcon icon;

  /// The big figure on the slip: the amount, as typed or as saved.
  final Widget figure;
  final String caption;
  final Widget body;
  final bool saveFailed;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const HisaabBackButton(),
            const SizedBox(width: HisaabSpacing.s),
            Expanded(child: Semantics(header: true, child: Text(question, style: text.titleLarge))),
          ],
        ),
        const SizedBox(height: HisaabSpacing.s),
        BillSlip(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              BillHead(name: name, icon: icon),
              const SizedBox(height: 6),
              figure,
              Text(caption, style: text.bodyMedium?.copyWith(color: context.colors.displayInk2)),
            ],
          ),
        ),
        if (saveFailed) ...<Widget>[
          const SizedBox(height: HisaabSpacing.s),
          Semantics(liveRegion: true, child: Text(AppLocalizations.of(context).couldntSave, style: text.titleMedium)),
        ],
        const SizedBox(height: HisaabSpacing.s),
        body,
      ],
    );
  }
}
