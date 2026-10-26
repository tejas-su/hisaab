import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/day_of_month_grid.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../cubit/bill_editor_cubit.dart';
import '../cubit/bill_editor_state.dart';
import 'bill_question.dart';

/// Step 3 of the bill editor: the day of the month it goes out; tapping a day saves.
class BillDayStep extends StatelessWidget {
  const BillDayStep({super.key, required this.form});

  final BillEditorInProgress form;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return AdaptiveSplit(
      header: BillQuestion(
        question: strings.billDayQuestion(form.label),
        children: <Widget>[
          if (form.saveFailed) ...<Widget>[
            const SizedBox(height: HisaabSpacing.l),
            Text(strings.couldntSave, style: Theme.of(context).textTheme.titleMedium),
          ],
        ],
      ),
      controls: DayOfMonthGrid(onDay: context.read<BillEditorCubit>().chooseDay),
    );
  }
}
