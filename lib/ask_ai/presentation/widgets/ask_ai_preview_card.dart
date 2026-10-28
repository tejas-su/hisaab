import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';
import '../bloc/ask_ai_state.dart';
import 'prompt_preview.dart';

/// "What will be sent" and, below a hairline, *Hide my notes*, in one near-white card
/// (FR-AI-2, FR-AI-3). Rows in a card are split by hairlines; never a card inside a card (D45).
///
/// Needs an [AskAiBloc] above it.
class AskAiPreviewCard extends StatelessWidget {
  const AskAiPreviewCard({super.key, required this.ready});

  final AskAiReady ready;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('prompt-preview'),
    padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.gutter, HisaabSpacing.gutter, HisaabSpacing.xs),
    decoration: ShapeDecoration(color: context.colors.surface, shape: HisaabShapes.squircle(HisaabRadii.card)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PromptPreview(prompt: ready.prompt),
        const SizedBox(height: HisaabSpacing.m),
        Divider(color: context.colors.hairline),
        // why: the tile paints its ripple on the nearest Material, which the card's fill would hide.
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            key: const ValueKey<String>('hide-notes'),
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(AppLocalizations.of(context).askHideNotes),
            value: ready.choice.hideNotes,
            onChanged: (bool hide) => context.read<AskAiBloc>().add(AskAiNotesHidden(hide: hide)),
          ),
        ),
      ],
    ),
  );
}
