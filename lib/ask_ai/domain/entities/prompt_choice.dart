import 'package:equatable/equatable.dart';

import '../ask_goal.dart';

/// What the user picked on the Ask AI screen (SPEC BR-15 inputs, FR-AI-1, FR-AI-2).
final class PromptChoice extends Equatable {
  const PromptChoice({this.goal = AskGoal.reviewMonth, this.period = AskPeriod.thisCycle, this.hideNotes = false, this.question = ''});

  /// The longest own question the field accepts (FR-AI-1).
  static const int maxQuestionLength = 200;

  final AskGoal goal;
  final AskPeriod period;

  /// Drops the note column from the entries CSV.
  final bool hideNotes;

  /// The own question as typed; only used when [goal] is [AskGoal.ownQuestion].
  final String question;

  /// False only for an own question that is still blank, so there is nothing to ask.
  bool get canSend => goal != AskGoal.ownQuestion || question.trim().isNotEmpty;

  /// Returns a copy with the given fields replaced.
  PromptChoice copyWith({AskGoal? goal, AskPeriod? period, bool? hideNotes, String? question}) => PromptChoice(
    goal: goal ?? this.goal,
    period: period ?? this.period,
    hideNotes: hideNotes ?? this.hideNotes,
    question: question ?? this.question,
  );

  @override
  List<Object?> get props => <Object?>[goal, period, hideNotes, question];
}
