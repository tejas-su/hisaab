import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/onboarding_step.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_state.dart';
import 'amount_controls.dart';
import '../../../core/widgets/amount_display.dart';
import 'daily_preview.dart';
import 'step_header.dart';

/// Step 1: "How much money comes in each month?" with the keypad open (SPEC FR-ON-2).
class IncomeStep extends StatelessWidget {
  const IncomeStep({super.key, required this.state});

  final OnboardingInProgress state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool hasAmount = !state.draft.income.isZero;
    return AdaptiveSplit(
      header: StepHeader(
        step: OnboardingStep.income,
        question: strings.incomeQuestion,
        hint: strings.incomeHint,
        children: <Widget>[
          const SizedBox(height: 22),
          AmountDisplay(amount: state.draft.income, rejections: state.rejections),
          if (hasAmount) ...<Widget>[
            const SizedBox(height: HisaabSpacing.l),
            DailyPreview(monthly: state.draft.income),
          ],
        ],
      ),
      controls: AmountControls(bloc: context.read<OnboardingBloc>(), canContinue: hasAmount),
    );
  }
}
