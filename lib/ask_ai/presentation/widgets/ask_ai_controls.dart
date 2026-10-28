import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/ask_goal.dart';
import '../../domain/entities/prompt_choice.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';
import 'goal_row.dart';
import 'own_question_row.dart';
import 'period_switch.dart';

/// The "what to ask" card (FR-AI-1, FR-AI-2), built like the Today list: a near-white card of
/// goal rows split by hairlines indented to the text, the own-question row last, then the
/// period switch (D45, D67).
///
/// Needs an [AskAiBloc] above it; [choice] is what is picked now.
class AskAiControls extends StatelessWidget {
  const AskAiControls({super.key, required this.choice});

  /// Where row text starts inside the card: the inset, the icon well and its gap.
  static const double textInset = HisaabSpacing.gutter + GoalRow.well + HisaabSpacing.m;

  static const List<AskGoal> _starters = <AskGoal>[AskGoal.reviewMonth, AskGoal.helpMeSave, AskGoal.makeBudget, AskGoal.onTrack];

  final PromptChoice choice;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AskAiBloc bloc = context.read<AskAiBloc>();
    final Divider hairline = Divider(indent: textInset, endIndent: HisaabSpacing.gutter, color: context.colors.hairline);
    return Container(
      key: const ValueKey<String>('ask-ai-choices'),
      padding: const EdgeInsetsDirectional.only(top: 6, bottom: HisaabSpacing.gutter),
      decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, 6),
            child: Semantics(header: true, child: Text(strings.askAiQuestion, style: Theme.of(context).textTheme.titleLarge)),
          ),
          for (final AskGoal goal in _starters) ...<Widget>[
            GoalRow(
              key: ValueKey<String>('goal-${goal.name}'),
              label: _label(strings, goal),
              icon: _icon(goal),
              selected: choice.goal == goal,
              onPressed: () => bloc.add(AskAiGoalChosen(goal)),
            ),
            hairline,
          ],
          OwnQuestionRow(
            key: const ValueKey<String>('goal-ownQuestion'),
            initial: choice.question,
            selected: choice.goal == AskGoal.ownQuestion,
          ),
          const SizedBox(height: HisaabSpacing.m),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
            child: PeriodSwitch(period: choice.period, onChanged: (AskPeriod period) => bloc.add(AskAiPeriodChosen(period))),
          ),
        ],
      ),
    );
  }

  static String _label(AppLocalizations strings, AskGoal goal) => switch (goal) {
    AskGoal.reviewMonth => strings.askGoalReview,
    AskGoal.helpMeSave => strings.askGoalSave,
    AskGoal.makeBudget => strings.askGoalBudget,
    AskGoal.onTrack => strings.askGoalOnTrack,
    AskGoal.ownQuestion => strings.askGoalOwn,
  };

  static AppIconData _icon(AskGoal goal) => switch (goal) {
    AskGoal.reviewMonth => AppIcons.askReview,
    AskGoal.helpMeSave => AppIcons.askSave,
    AskGoal.makeBudget => AppIcons.askBudget,
    AskGoal.onTrack => AppIcons.askOnTrack,
    AskGoal.ownQuestion => AppIcons.askOwn,
  };
}
