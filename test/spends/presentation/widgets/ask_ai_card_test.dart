import 'package:expense_tracker/spends/presentation/widgets/ask_ai_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AskAiCard (FR-SP-2)', () {
    testWidgets('names the cycle and opens Ask AI on tap', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, Scaffold(body: AskAiCard(cycleLabel: 'October', onPressed: () => taps++)));
      expect(find.text('Ask AI about October — get a second opinion in one tap.'), findsOneWidget);
      await tester.tap(find.byType(AskAiCard));
      expect(taps, 1);
    });

    testWidgets('TalkBack reads it as one button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, Scaffold(body: AskAiCard(cycleLabel: 'October', onPressed: () {})));
      expect(
        tester.getSemantics(find.byType(AskAiCard)),
        isSemantics(label: 'Ask AI about October — get a second opinion in one tap.', isButton: true),
      );
      handle.dispose();
    });
  });
}
