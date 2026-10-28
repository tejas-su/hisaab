import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/ask_goal.dart';
import '../../domain/entities/prompt_choice.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';
import 'goal_check.dart';
import 'goal_well.dart';

/// The last goal row: an always-visible field for the user's own question (FR-AI-1).
///
/// Tapping it or typing in it picks *Ask my own question*, so a typed question is never a
/// hidden second step (prompt starters with "describe your own", D67). Needs an [AskAiBloc]
/// above it. The text controller is this widget's own leaf state.
class OwnQuestionRow extends StatefulWidget {
  const OwnQuestionRow({super.key, required this.initial, required this.selected});

  final String initial;
  final bool selected;

  @override
  State<OwnQuestionRow> createState() => _OwnQuestionRowState();
}

class _OwnQuestionRowState extends State<OwnQuestionRow> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AskAiBloc bloc = context.read<AskAiBloc>();
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: 9),
      child: Row(
        children: <Widget>[
          const GoalWell(icon: AppIcons.askOwn),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            child: TextField(
              key: const ValueKey<String>('own-question'),
              controller: _controller,
              maxLength: PromptChoice.maxQuestionLength,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: Theme.of(context).textTheme.titleMedium,
              onTap: () => bloc.add(const AskAiGoalChosen(AskGoal.ownQuestion)),
              onChanged: (String question) => bloc.add(AskAiQuestionChanged(question)),
              onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).askGoalOwn,
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                // why: the field is the row's tap target, so it keeps the 48dp minimum (NFR-4).
                constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
                contentPadding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.m),
              ),
            ),
          ),
          if (widget.selected) const GoalCheck(),
        ],
      ),
    );
  }
}
