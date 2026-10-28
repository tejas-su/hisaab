import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/prompt_choice.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';

/// The 200-character field under *Ask my own question* (FR-AI-1); starts from [initial].
///
/// Needs an [AskAiBloc] above it. The text controller is this widget's own leaf state.
class OwnQuestionField extends StatefulWidget {
  const OwnQuestionField({super.key, required this.initial});

  final String initial;

  @override
  State<OwnQuestionField> createState() => _OwnQuestionFieldState();
}

class _OwnQuestionFieldState extends State<OwnQuestionField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey<String>('own-question'),
    controller: _controller,
    autofocus: true,
    maxLength: PromptChoice.maxQuestionLength,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: TextInputAction.done,
    onChanged: (String question) => context.read<AskAiBloc>().add(AskAiQuestionChanged(question)),
    onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
    decoration: InputDecoration(
      hintText: AppLocalizations.of(context).askOwnHint,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(HisaabRadii.chip))),
    ),
  );
}
