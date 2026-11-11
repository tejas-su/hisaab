import 'package:hisaab/ask_ai/ask_ai.dart';
import 'package:hisaab/ask_ai/domain/ask_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AskAi events compare by their fields', () {
    expect(const AskAiLoadRequested().props, isEmpty);
    expect(const AskAiGoalChosen(AskGoal.onTrack).props, <Object?>[AskGoal.onTrack]);
    expect(const AskAiPeriodChosen(AskPeriod.lastThreeCycles).props, <Object?>[AskPeriod.lastThreeCycles]);
    expect(const AskAiNotesHidden(hide: true).props, <Object?>[true]);
    expect(const AskAiQuestionChanged('Why?').props, <Object?>['Why?']);
    expect(const AskAiChatGptPressed().props, isEmpty);
    expect(const AskAiOtherAiPressed().props, isEmpty);
    expect(const AskAiCopyPressed().props, isEmpty);
  });
}
