import 'package:equatable/equatable.dart';

import '../../domain/ask_goal.dart';

/// What happens on the Ask AI screen.
sealed class AskAiEvent extends Equatable {
  const AskAiEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The screen opened; load the data the prompt is built from.
final class AskAiLoadRequested extends AskAiEvent {
  const AskAiLoadRequested();
}

/// The user tapped a goal card (FR-AI-1).
final class AskAiGoalChosen extends AskAiEvent {
  const AskAiGoalChosen(this.goal);

  final AskGoal goal;

  @override
  List<Object?> get props => <Object?>[goal];
}

/// The user tapped a period chip (FR-AI-2).
final class AskAiPeriodChosen extends AskAiEvent {
  const AskAiPeriodChosen(this.period);

  final AskPeriod period;

  @override
  List<Object?> get props => <Object?>[period];
}

/// The user flipped *Hide my notes* (FR-AI-2).
final class AskAiNotesHidden extends AskAiEvent {
  const AskAiNotesHidden({required this.hide});

  final bool hide;

  @override
  List<Object?> get props => <Object?>[hide];
}

/// The user typed in the own-question field (FR-AI-1).
final class AskAiQuestionChanged extends AskAiEvent {
  const AskAiQuestionChanged(this.question);

  final String question;

  @override
  List<Object?> get props => <Object?>[question];
}

/// A tap that hands the prompt to another app; a second one while the first runs is dropped.
sealed class AskAiHandoffEvent extends AskAiEvent {
  const AskAiHandoffEvent();
}

/// The user tapped *Copy & open ChatGPT*.
final class AskAiChatGptPressed extends AskAiHandoffEvent {
  const AskAiChatGptPressed();
}

/// The user tapped *Other AI* (the share sheet).
final class AskAiOtherAiPressed extends AskAiHandoffEvent {
  const AskAiOtherAiPressed();
}

/// The user tapped *Copy only*.
final class AskAiCopyPressed extends AskAiHandoffEvent {
  const AskAiCopyPressed();
}
