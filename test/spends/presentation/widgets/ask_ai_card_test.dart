import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/spends/presentation/widgets/ask_ai_card.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AskAiCard (FR-SP-2)', () {
    testWidgets('names the cycle and opens Ask AI on tap', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: AskAiCard(cycleLabel: 'October', onPressed: () => taps++),
        ),
      );
      expect(find.text('Ask AI about October — get a second opinion in one tap.'), findsOneWidget);
      await tester.tap(find.byType(AskAiCard));
      expect(taps, 1);
    });

    testWidgets('TalkBack reads it as one button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Scaffold(
          body: AskAiCard(cycleLabel: 'October', onPressed: () {}),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AskAiCard)),
        isSemantics(label: 'Ask AI about October — get a second opinion in one tap.', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('is a borderless near-white card, like every other card (D45)', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: AskAiCard(cycleLabel: 'October', onPressed: () {}),
        ),
      );
      final Container card = tester.widget<Container>(find.byKey(const ValueKey<String>('ask-ai-card-surface')));
      final ShapeDecoration decoration = card.decoration! as ShapeDecoration;
      expect(decoration.color, HisaabColors.light.surface);
      expect((decoration.shape as SmoothRectangleBorder).side, BorderSide.none);
    });
  });
}
