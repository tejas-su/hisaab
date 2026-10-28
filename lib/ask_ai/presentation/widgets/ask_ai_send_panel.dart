import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';
import '../bloc/ask_ai_state.dart';
import 'prompt_preview.dart';

/// The preview, *Hide my notes* and the three hand-off actions (FR-AI-2, FR-AI-3, FR-AI-4).
///
/// Needs an [AskAiBloc] above it. The actions are disabled while an own question is blank.
class AskAiSendPanel extends StatelessWidget {
  const AskAiSendPanel({super.key, required this.ready});

  final AskAiReady ready;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AskAiBloc bloc = context.read<AskAiBloc>();
    final bool canSend = ready.choice.canSend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PromptPreview(key: const ValueKey<String>('prompt-preview'), prompt: ready.prompt),
        const SizedBox(height: HisaabSpacing.s),
        SwitchListTile(
          key: const ValueKey<String>('hide-notes'),
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(strings.askHideNotes),
          value: ready.choice.hideNotes,
          onChanged: (bool hide) => bloc.add(AskAiNotesHidden(hide: hide)),
        ),
        const SizedBox(height: HisaabSpacing.m),
        SignalKey(
          key: const ValueKey<String>('open-chatgpt'),
          label: strings.askOpenChatGpt,
          icon: AppIcons.askAi,
          onPressed: canSend ? () => bloc.add(const AskAiChatGptPressed()) : null,
        ),
        const SizedBox(height: HisaabSpacing.s),
        Row(
          children: <Widget>[
            Expanded(
              child: HisaabChip(
                key: const ValueKey<String>('other-ai'),
                label: strings.askOtherAi,
                icon: AppIcons.share,
                expand: true,
                onPressed: canSend ? () => bloc.add(const AskAiOtherAiPressed()) : null,
              ),
            ),
            const SizedBox(width: HisaabSpacing.s),
            Expanded(
              child: HisaabChip(
                key: const ValueKey<String>('copy-only'),
                label: strings.askCopyOnly,
                icon: AppIcons.copy,
                expand: true,
                onPressed: canSend ? () => bloc.add(const AskAiCopyPressed()) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
