import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/bill_draft.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/onboarding_step.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import 'amount_controls.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/day_of_month_grid.dart';
import 'step_header.dart';

/// One bill being added: its amount on a mini keypad, then the day it goes out (FR-ON-4).
class BillEditorView extends StatelessWidget {
  const BillEditorView({super.key, required this.editor, required this.draft, required this.rejections});

  final BillEditor editor;
  final OnboardingDraft draft;
  final int rejections;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final OnboardingBloc bloc = context.read<OnboardingBloc>();
    final String name = strings.billName(editor.kind.name);
    final bool alreadyAdded = draft.bills.any((BillDraft bill) => bill.kind == editor.kind);
    final Widget remove = alreadyAdded
        ? Padding(
            padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.l),
            child: HisaabChip(
              label: strings.removeBill(name),
              icon: AppIcons.delete,
              onPressed: () => bloc.add(OnboardingBillRemoved(editor.kind)),
            ),
          )
        : const SizedBox.shrink();
    return switch (editor.stage) {
      BillStage.amount => AdaptiveSplit(
          header: StepHeader(
            step: OnboardingStep.bills,
            question: strings.billAmountQuestion(name),
            children: <Widget>[
              const SizedBox(height: 22),
              AmountDisplay(amount: Money.fromMajor(editor.rupees), rejections: rejections),
              remove,
            ],
          ),
          controls: AmountControls(bloc: bloc, canContinue: editor.rupees > 0),
        ),
      BillStage.day => AdaptiveSplit(
          header: StepHeader(step: OnboardingStep.bills, question: strings.billDayQuestion(name)),
          controls: DayOfMonthGrid(onDay: (int day) => bloc.add(OnboardingBillDayChosen(day))),
        ),
    };
  }
}
