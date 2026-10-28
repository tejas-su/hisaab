import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';

/// The three hand-offs (FR-AI-4): the marigold *Copy & open ChatGPT*, then *Other apps* and
/// *Copy only*. All are disabled while [canSend] is false (a blank own question). When
/// [needsPaste], a caption above them says ChatGPT will open empty, before the tap (D74).
///
/// The page pins this to the bottom so it stays in thumb reach (D67). Needs an [AskAiBloc] above it.
class AskAiActions extends StatelessWidget {
  const AskAiActions({super.key, required this.canSend, required this.needsPaste});

  final bool canSend;
  final bool needsPaste;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AskAiBloc bloc = context.read<AskAiBloc>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (needsPaste) ...<Widget>[
          Text(
            strings.askPasteNeeded,
            key: const ValueKey<String>('paste-needed'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2),
          ),
          const SizedBox(height: HisaabSpacing.s),
        ],
        SignalKey(
          key: const ValueKey<String>('open-chatgpt'),
          label: strings.askOpenChatGpt,
          icon: AppIcons.askAi,
          onPressed: canSend ? () => bloc.add(const AskAiChatGptPressed()) : null,
        ),
        const SizedBox(height: HisaabSpacing.s),
        Row(
          spacing: HisaabSpacing.s,
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
