import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/time/pay_rule.dart';
import '../../../../core/widgets/day_of_month_grid.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/income_sheet_bloc.dart';
import '../../bloc/income_sheet_event.dart';
import '../../bloc/income_sheet_state.dart';
import 'income_step_frame.dart';

/// *Pick a date* on the *When it comes* question: the 1–31 grid with the picked day marked; a tap
/// picks it and returns to the choices (SPEC FR-SE-1, D140).
class IncomeDayQuestion extends StatelessWidget {
  const IncomeDayQuestion({super.key, required this.state});

  final IncomeSheetReady state;

  @override
  Widget build(BuildContext context) => IncomeStepFrame(
        question: AppLocalizations.of(context).pickPaydayQuestion,
        body: DayOfMonthGrid(
          selected: state.draft.flatMap((PayRule rule) => rule is MonthlyOnDay ? Option<int>.of(rule.day) : const Option<int>.none()),
          onDay: (int day) => context.read<IncomeSheetBloc>().add(IncomeSheetPayRuleChosen(MonthlyOnDay(day))),
        ),
      );
}
