import 'package:expense_tracker/ask_ai/ask_ai.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_choice.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ask_ai/prompt_input.dart';

void main() {
  test('AskAi states compare by their fields', () {
    final PromptInput input = workedPromptInput();
    const PromptText prompt = PromptText(text: 'Task: Why?', entryCount: 1, groupedWeeks: 0);
    expect(const AskAiLoading().props, isEmpty);
    expect(const AskAiFailed().props, isEmpty);
    expect(
      AskAiReady(input: input, choice: const PromptChoice(), prompt: prompt, toasts: 2).props,
      <Object?>[input, const PromptChoice(), prompt, 2],
    );
  });

  test('PromptText and PromptInput compare by their fields', () {
    const PromptText prompt = PromptText(text: 'a', entryCount: 3, groupedWeeks: 1);
    expect(prompt.props, <Object?>['a', 3, 1]);
    final PromptInput input = workedPromptInput();
    expect(input.props, <Object?>[
      input.cycles,
      input.today,
      input.incomeRule,
      input.payRule,
      input.bills,
      input.categories,
      input.entries,
    ]);
  });
}
