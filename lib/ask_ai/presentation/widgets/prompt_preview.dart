import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/prompt_text.dart';

/// "What will be sent": the prompt's first lines, expandable to the whole text (FR-AI-3).
///
/// It draws no card: its parent places it in one. Whether it is expanded is this widget's own
/// leaf state.
class PromptPreview extends StatefulWidget {
  const PromptPreview({super.key, required this.prompt});

  /// How many lines show before *Show full text*.
  static const int collapsedLines = 4;

  final PromptText prompt;

  @override
  State<PromptPreview> createState() => _PromptPreviewState();
}

class _PromptPreviewState extends State<PromptPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final PromptText prompt = widget.prompt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.askPreviewTitle(prompt.entryCount), style: text.titleSmall),
        if (prompt.groupedWeeks > 0) ...<Widget>[
          const SizedBox(height: HisaabSpacing.xs),
          Text(strings.askPreviewGrouped, style: HisaabType.regular(text.bodySmall)?.copyWith(color: context.colors.ink2)),
        ],
        const SizedBox(height: HisaabSpacing.m),
        Text(
          _expanded ? prompt.text : prompt.text.split('\n').take(PromptPreview.collapsedLines).join('\n'),
          style: HisaabType.regular(text.bodySmall)?.copyWith(color: context.colors.ink2),
        ),
        const SizedBox(height: HisaabSpacing.m),
        HisaabChip(
          key: const ValueKey<String>('show-full-text'),
          label: _expanded ? strings.askShowLess : strings.askShowFull,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
      ],
    );
  }
}
