import 'package:equatable/equatable.dart';

import '../../domain/entities/prompt_choice.dart';
import '../../domain/entities/prompt_input.dart';
import '../../domain/entities/prompt_text.dart';

/// What the Ask AI screen shows.
sealed class AskAiState extends Equatable {
  const AskAiState();

  @override
  List<Object?> get props => <Object?>[];
}

/// The data is loading; the controls show without a preview.
final class AskAiLoading extends AskAiState {
  const AskAiLoading();
}

/// The user's [choice] and the [prompt] it builds from [input].
///
/// [toasts] counts the times "Copied. Paste it in the chat." should have shown; the page shows
/// one each time it goes up (DECISIONS D63).
final class AskAiReady extends AskAiState {
  const AskAiReady({required this.input, required this.choice, required this.prompt, this.toasts = 0});

  final PromptInput input;
  final PromptChoice choice;
  final PromptText prompt;
  final int toasts;

  @override
  List<Object?> get props => <Object?>[input, choice, prompt, toasts];
}

/// Loading failed; a quiet message with Try again.
final class AskAiFailed extends AskAiState {
  const AskAiFailed();
}
