import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/time/pay_rule.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/income_sheet_bloc.dart';
import '../../bloc/income_sheet_event.dart';
import '../../bloc/income_sheet_state.dart';
import 'income_copy.dart';
import 'income_effect.dart';
import 'income_step_frame.dart';

/// The *When it comes* question (SPEC FR-SE-1, BR-1a, D140, mockup 32): onboarding's five choices
/// with the picked one checked, what the change does, and *Save*.
class IncomeWhenQuestion extends StatelessWidget {
  const IncomeWhenQuestion({super.key, required this.state});

  final IncomeSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final IncomeSheetBloc bloc = context.read<IncomeSheetBloc>();
    final PayRule? draft = state.draft.toNullable();
    final CycleSummary? preview = state.draftChanged ? state.preview.toNullable() : null;
    return IncomeStepFrame(
      question: strings.paydayQuestion,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _choice('first', strings.payFirstOfMonth, draft == const MonthlyOnDay(1), () => bloc.add(const IncomeSheetPayRuleChosen(MonthlyOnDay(1)))),
          _choice('last', strings.payLastDay, draft is LastDayOfMonth, () => bloc.add(const IncomeSheetPayRuleChosen(LastDayOfMonth()))),
          _choice(
            'date',
            strings.payPickDate,
            draft is MonthlyOnDay && draft != const MonthlyOnDay(1),
            () => bloc.add(const IncomeSheetDayGridOpened()),
            detail: draft is MonthlyOnDay && draft != const MonthlyOnDay(1) ? context.payRuleWhen(draft) : null,
          ),
          _choice(
            'week',
            strings.payEveryWeek,
            draft is WeeklyOn,
            () => bloc.add(const IncomeSheetWeekdayGridOpened()),
            detail: draft is WeeklyOn ? context.payRuleWhen(draft) : null,
          ),
          _choice('changes', strings.payItChanges, draft is IrregularIncome, () => bloc.add(const IncomeSheetPayRuleChosen(IrregularIncome()))),
          if (preview != null) ...<Widget>[const SizedBox(height: HisaabSpacing.s), IncomeEffect(preview: preview)],
          if (state.saveFailed) ...<Widget>[
            const SizedBox(height: HisaabSpacing.s),
            Semantics(liveRegion: true, child: Text(strings.couldntSave, style: Theme.of(context).textTheme.titleMedium)),
          ],
          const SizedBox(height: HisaabSpacing.m),
          SignalKey(
            key: const ValueKey<String>('income-when-save'),
            label: strings.save,
            onPressed: state.draftChanged && !state.saving ? () => bloc.add(const IncomeSheetPayRuleSaved()) : null,
          ),
        ],
      ),
    );
  }

  static Widget _choice(String id, String label, bool selected, VoidCallback onPressed, {String? detail}) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.s),
        child: HisaabChip(
          key: ValueKey<String>('income-when-$id'),
          label: label,
          detail: detail,
          selected: selected,
          expand: true,
          onPressed: onPressed,
        ),
      );
}
