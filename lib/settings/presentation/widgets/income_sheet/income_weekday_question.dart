import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/time/pay_rule.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/income_sheet_bloc.dart';
import '../../bloc/income_sheet_event.dart';
import '../../bloc/income_sheet_state.dart';
import 'income_copy.dart';
import 'income_step_frame.dart';

/// *Every week* on the *When it comes* question: the seven weekdays with the picked one checked;
/// a tap picks it and returns to the choices (SPEC FR-SE-1, D140).
class IncomeWeekdayQuestion extends StatelessWidget {
  const IncomeWeekdayQuestion({super.key, required this.state});

  final IncomeSheetReady state;

  @override
  Widget build(BuildContext context) {
    final PayRule? draft = state.draft.toNullable();
    return IncomeStepFrame(
      question: AppLocalizations.of(context).pickWeekdayQuestion,
      body: Wrap(
        spacing: HisaabSpacing.s,
        runSpacing: HisaabSpacing.s,
        children: <Widget>[
          for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
            HisaabChip(
              key: ValueKey<String>('income-weekday-$weekday'),
              label: context.weekdayName(weekday),
              selected: draft == WeeklyOn(weekday),
              onPressed: () => context.read<IncomeSheetBloc>().add(IncomeSheetPayRuleChosen(WeeklyOn(weekday))),
            ),
        ],
      ),
    );
  }
}
