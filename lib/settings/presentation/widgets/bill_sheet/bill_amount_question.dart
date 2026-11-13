import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/keypad.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/presentation/rule_glyph.dart';
import '../../../../ledger/presentation/rule_words.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'pinned_bill_question.dart';

/// The amount question: the keypad, prefilled with the bill's amount, and *Save*
/// (SPEC FR-SE-1 AC-3, AC-4).
class BillAmountQuestion extends StatelessWidget {
  const BillAmountQuestion({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillSheetBloc bloc = context.read<BillSheetBloc>();
    final Money typed = Money.fromMajor(state.rupees);
    final bool changed = typed != state.rule.amount;
    return PinnedBillQuestion(
      question: strings.ruleAmountQuestion(state.rule.kind, state.rule.label, state.rule.amountMode),
      name: state.rule.label,
      glyph: state.rule.glyph,
      figure: AmountDisplay(amount: typed, rejections: state.rejections),
      caption: changed ? strings.billWas(context.money.format(state.rule.amount)) : strings.billEveryMonth(state.rule.schedule.anchor.day),
      saveFailed: state.saveFailed,
      controls: (BuildContext context, double keyHeight) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Keypad(
            keyHeight: keyHeight,
            onKey: (String key) => bloc.add(BillSheetKeyPressed(key)),
            onBackspace: () => bloc.add(const BillSheetBackspacePressed()),
            onClear: () => bloc.add(const BillSheetCleared()),
          ),
          const SizedBox(height: HisaabSpacing.m),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('bill-sheet-save'),
              label: strings.save,
              onPressed: state.rupees > 0 && !state.saving ? () => bloc.add(const BillSheetAmountSaved()) : null,
            ),
          ),
        ],
      ),
    );
  }
}
