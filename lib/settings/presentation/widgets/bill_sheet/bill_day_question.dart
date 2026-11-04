import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/day_of_month_grid.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_question_frame.dart';

/// The day question: the 1–31 grid with the current day picked; a tap saves
/// (SPEC FR-SE-1 AC-3, AC-4, D34).
class BillDayQuestion extends StatelessWidget {
  const BillDayQuestion({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final int day = state.rule.schedule.anchor.day;
    return BillQuestionFrame(
      question: strings.billDayQuestion(state.rule.label),
      name: state.rule.label,
      icon: state.rule.shownIcon,
      figure: AmountText(state.rule.amount, roll: false, style: Theme.of(context).textTheme.displaySmall),
      caption: strings.billEveryMonth(day),
      saveFailed: state.saveFailed,
      body: DayOfMonthGrid(
        selected: Option<int>.of(day),
        onDay: (int day) => context.read<BillSheetBloc>().add(BillSheetDayChosen(day)),
      ),
    );
  }
}
