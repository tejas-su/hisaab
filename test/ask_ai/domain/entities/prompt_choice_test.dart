import 'package:expense_tracker/ask_ai/domain/ask_goal.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptChoice.canSend (FR-AI-1)', () {
    test('is false for a blank own question', () {
      expect(const PromptChoice(goal: AskGoal.ownQuestion, question: '  ').canSend, isFalse);
    });

    test('is true for a typed own question', () {
      expect(const PromptChoice(goal: AskGoal.ownQuestion, question: 'Can I buy a bike?').canSend, isTrue);
    });

    test('is true for every other goal, even with no question', () {
      expect(const PromptChoice().canSend, isTrue);
    });
  });

  test('defaults to Review my month, this cycle, notes shown', () {
    expect(
      const PromptChoice(),
      const PromptChoice(goal: AskGoal.reviewMonth, period: AskPeriod.thisCycle, hideNotes: false, question: ''),
    );
  });

  test('copyWith replaces only the given fields', () {
    const PromptChoice choice = PromptChoice(goal: AskGoal.ownQuestion, question: 'Why?');
    expect(
      choice.copyWith(period: AskPeriod.lastThreeCycles, hideNotes: true),
      const PromptChoice(goal: AskGoal.ownQuestion, period: AskPeriod.lastThreeCycles, hideNotes: true, question: 'Why?'),
    );
    expect(choice.copyWith(goal: AskGoal.onTrack, question: 'How?'), const PromptChoice(goal: AskGoal.onTrack, question: 'How?'));
  });

  test('cycleCount is 1 for this cycle and 3 for the last three', () {
    expect(AskPeriod.thisCycle.cycleCount, 1);
    expect(AskPeriod.lastThreeCycles.cycleCount, 3);
  });
}
