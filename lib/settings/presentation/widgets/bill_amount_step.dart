import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_words.dart';
import '../bloc/bill_editor_bloc.dart';
import '../bloc/bill_editor_event.dart';
import '../bloc/bill_editor_state.dart';
import 'bill_question.dart';

/// Step 2 of the bill editor: the amount on the in-app keypad, then Next.
class BillAmountStep extends StatelessWidget {
  const BillAmountStep({super.key, required this.form});

  final BillEditorInProgress form;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillEditorBloc bloc = context.read<BillEditorBloc>();
    final bool short = context.layout.heightClass == HeightClass.compact;
    final AmountMode mode = form.kind.match(() => AmountMode.fixed, (BillKind kind) => kind.amountMode);
    return AdaptiveSplit(
      header: BillQuestion(
        question: strings.ruleAmountQuestion(bloc.kind, form.label, mode),
        children: <Widget>[
          // why: a card bill must say why it isn't counted, or the user adds it twice (D123).
          if (mode == AmountMode.card) ...<Widget>[
            const SizedBox(height: HisaabSpacing.s),
            Text(strings.billCardHint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2)),
          ],
          const SizedBox(height: 22),
          AmountDisplay(amount: Money.fromMajor(form.rupees), rejections: form.rejections),
        ],
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Keypad(
            keyHeight: short ? HisaabSizes.minTouchTarget : 60,
            onKey: (String key) => bloc.add(BillEditorKeyPressed(key)),
            onBackspace: () => bloc.add(const BillEditorBackspacePressed()),
            onClear: () => bloc.add(const BillEditorCleared()),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('bill-next'),
              label: strings.next,
              icon: AppIcons.next,
              onPressed: form.rupees > 0 ? () => bloc.add(const BillEditorNextPressed()) : null,
            ),
          ),
        ],
      ),
    );
  }
}
