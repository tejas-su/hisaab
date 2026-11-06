import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/pay_rule.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/keypad.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/income_sheet_bloc.dart';
import '../../bloc/income_sheet_event.dart';
import '../../bloc/income_sheet_state.dart';
import '../bill_sheet/bill_question_frame.dart';
import 'income_copy.dart';
import 'income_effect.dart';

/// The income amount question (SPEC FR-SE-1, D137, D140): onboarding's question on the keypad and
/// *Save*. For the salary rule it is prefilled with the monthly income and says the change counts
/// from the next payday; for a fixed day picked after "It changes" it is prefilled with what came
/// in this month and shows what the new payday does.
class IncomeAmountQuestion extends StatelessWidget {
  const IncomeAmountQuestion({super.key, required this.state});

  final IncomeSheetReady state;

  static const double _keyHeight = 56;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final IncomeSheetBloc bloc = context.read<IncomeSheetBloc>();
    final Money typed = Money.fromMajor(state.rupees);
    return BillQuestionFrame(
      question: strings.incomeQuestion,
      name: strings.moneyComingIn,
      glyph: AppIcons.forKey(CategoryKeys.salary),
      figure: AmountDisplay(amount: typed, rejections: state.rejections),
      caption: _caption(context, typed),
      saveFailed: state.saveFailed,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _effect(context),
          const SizedBox(height: HisaabSpacing.m),
          Keypad(
            keyHeight: _keyHeight,
            onKey: (String key) => bloc.add(IncomeSheetKeyPressed(key)),
            onBackspace: () => bloc.add(const IncomeSheetBackspacePressed()),
            onClear: () => bloc.add(const IncomeSheetCleared()),
          ),
          const SizedBox(height: HisaabSpacing.m),
          SignalKey(
            key: const ValueKey<String>('income-sheet-save'),
            label: strings.save,
            onPressed: state.rupees > 0 && !state.saving ? () => bloc.add(const IncomeSheetAmountSaved()) : null,
          ),
        ],
      ),
    );
  }

  String _caption(BuildContext context, Money typed) => state.pendingRule.match(
        () => state.income.rule.match(
          () => '',
          (RecurringRule rule) {
            final Money monthly = IncomeAmount.monthlyOf(rule);
            return typed != monthly ? AppLocalizations.of(context).billWas(context.money.format(monthly)) : context.incomeComes(rule);
          },
        ),
        (PayRule rule) => context.payRuleComes(rule),
      );

  // why: the one thing to know before saving is when the change counts (D137), or for a new
  // payday how long the money already here now lasts (D140).
  Widget _effect(BuildContext context) => state.pendingRule.match(
        () => state.income.rule.match(() => const SizedBox.shrink(), (RecurringRule rule) => _fromPayday(context, rule)),
        (PayRule _) => state.preview.match(() => const SizedBox.shrink(), (CycleSummary preview) => IncomeEffect(preview: preview)),
      );

  Widget _fromPayday(BuildContext context, RecurringRule rule) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.incomeFromPayday(context.incomeDate(rule.nextDue)), style: text.titleMedium),
          ...state.income.latestPay.match(
            () => const <Widget>[],
            (Entry pay) => <Widget>[
              Text(
                strings.incomeStays(context.incomePeriod(rule), context.money.format(pay.amount)),
                style: text.bodyMedium?.copyWith(color: context.colors.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
