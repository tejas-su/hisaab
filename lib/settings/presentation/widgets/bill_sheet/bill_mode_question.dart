import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../../../ledger/presentation/rule_glyph.dart';
import '../../../../ledger/presentation/rule_words.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_question_frame.dart';

/// The *Kind of bill* question, "What kind of bill is it?": three answers stacked, the current one picked; a tap saves
/// (D123).
class BillModeQuestion extends StatelessWidget {
  const BillModeQuestion({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final RecurringRule rule = state.rule;
    return BillQuestionFrame(
      question: strings.billModeQuestion,
      name: rule.label,
      glyph: rule.glyph,
      figure: AmountText(rule.amount, roll: false, style: Theme.of(context).textTheme.displaySmall),
      caption: strings.billEveryMonth(rule.schedule.anchor.day),
      saveFailed: state.saveFailed,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (int index, AmountMode mode) in AmountMode.values.indexed) ...<Widget>[
            if (index > 0) const SizedBox(height: HisaabSpacing.s),
            HisaabChip(
              key: ValueKey<String>('bill-mode-${mode.name}'),
              label: strings.amountModeName(mode),
              selected: mode == rule.amountMode,
              expand: true,
              onSurface: true,
              onPressed: state.saving ? null : () => context.read<BillSheetBloc>().add(BillSheetModeChosen(mode)),
            ),
          ],
        ],
      ),
    );
  }
}
