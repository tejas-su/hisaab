import 'package:expense_tracker/ask_ai/domain/entities/prompt_text.dart';
import 'package:expense_tracker/ask_ai/presentation/widgets/prompt_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const PromptText _prompt = PromptText(text: 'one\ntwo\nthree\nfour\nfive\nsix', entryCount: 6, groupedWeeks: 0);

void main() {
  group('PromptPreview (FR-AI-3)', () {
    testWidgets('shows the entry count and the first 4 lines', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: PromptPreview(prompt: _prompt)),
        ),
      );
      expect(find.text('What the AI will see · 6 entries'), findsOneWidget);
      expect(find.text('one\ntwo\nthree\nfour'), findsOneWidget);
      expect(find.textContaining('five'), findsNothing);
    });

    testWidgets('Show full text expands to the whole prompt, Show less folds it', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: PromptPreview(prompt: _prompt)),
        ),
      );
      await tester.tap(find.text('Show full text'));
      await tester.pumpAndSettle();
      expect(find.text(_prompt.text), findsOneWidget);
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.text('one\ntwo\nthree\nfour'), findsOneWidget);
    });

    testWidgets('says 1 entry in the singular', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: PromptPreview(prompt: PromptText(text: 'a', entryCount: 1, groupedWeeks: 0)),
        ),
      );
      expect(find.text('What the AI will see · 1 entry'), findsOneWidget);
    });

    testWidgets('the grouped note shows only when weeks were grouped', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: PromptPreview(prompt: _prompt)),
        ),
      );
      expect(find.text('Older weeks are shown as totals to keep it short.'), findsNothing);
      await pumpApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: PromptPreview(prompt: PromptText(text: 'a', entryCount: 900, groupedWeeks: 3)),
          ),
        ),
      );
      expect(find.text('Older weeks are shown as totals to keep it short.'), findsOneWidget);
    });
  });
}
