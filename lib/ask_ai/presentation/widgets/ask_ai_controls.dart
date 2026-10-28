import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/ask_goal.dart';
import '../../domain/entities/prompt_choice.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';
import 'goal_card.dart';
import 'own_question_field.dart';

/// The goal cards in a 2×2 grid, *Ask my own question* and the period chips (FR-AI-1, FR-AI-2).
///
/// Needs an [AskAiBloc] above it; [choice] is what is selected now.
class AskAiControls extends StatelessWidget {
  const AskAiControls({super.key, required this.choice});

  final PromptChoice choice;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AskAiBloc bloc = context.read<AskAiBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(strings.askAiQuestion, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HisaabSpacing.m),
        _pair(context, AskGoal.reviewMonth, AskGoal.helpMeSave),
        const SizedBox(height: HisaabSpacing.s),
        _pair(context, AskGoal.makeBudget, AskGoal.onTrack),
        const SizedBox(height: HisaabSpacing.s),
        _goal(context, AskGoal.ownQuestion),
        if (choice.goal == AskGoal.ownQuestion) ...<Widget>[
          const SizedBox(height: HisaabSpacing.m),
          OwnQuestionField(initial: choice.question),
        ],
        const SizedBox(height: HisaabSpacing.l),
        Wrap(
          spacing: HisaabSpacing.s,
          runSpacing: HisaabSpacing.s,
          children: <Widget>[
            for (final AskPeriod period in AskPeriod.values)
              HisaabChip(
                key: ValueKey<String>('period-${period.name}'),
                label: switch (period) {
                  AskPeriod.thisCycle => strings.askPeriodThis,
                  AskPeriod.lastThreeCycles => strings.askPeriodThree,
                },
                selected: choice.period == period,
                onPressed: () => bloc.add(AskAiPeriodChosen(period)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pair(BuildContext context, AskGoal start, AskGoal end) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: _goal(context, start)),
        const SizedBox(width: HisaabSpacing.s),
        Expanded(child: _goal(context, end)),
      ],
    ),
  );

  Widget _goal(BuildContext context, AskGoal goal) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return GoalCard(
      key: ValueKey<String>('goal-${goal.name}'),
      label: switch (goal) {
        AskGoal.reviewMonth => strings.askGoalReview,
        AskGoal.helpMeSave => strings.askGoalSave,
        AskGoal.makeBudget => strings.askGoalBudget,
        AskGoal.onTrack => strings.askGoalOnTrack,
        AskGoal.ownQuestion => strings.askGoalOwn,
      },
      selected: choice.goal == goal,
      onPressed: () => context.read<AskAiBloc>().add(AskAiGoalChosen(goal)),
    );
  }
}
