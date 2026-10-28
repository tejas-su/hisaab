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
      expect(find.text('Ask an AI about October'), findsOneWidget);
      expect(find.text("You'll see exactly what it gets."), findsOneWidget);
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
        isSemantics(label: "Ask an AI about October, You'll see exactly what it gets.", isButton: true),
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

    testWidgets('the note is quieter: small ink2 text under the title', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: AskAiCard(cycleLabel: 'October', onPressed: () {}),
        ),
      );
      final ThemeData theme = Theme.of(tester.element(find.byType(AskAiCard)));
      final Text title = tester.widget<Text>(find.text('Ask an AI about October'));
      final Text note = tester.widget<Text>(find.text("You'll see exactly what it gets."));
      expect(title.style?.fontSize, theme.textTheme.bodyLarge?.fontSize);
      expect(note.style?.fontSize, theme.textTheme.bodySmall?.fontSize);
      expect(note.style?.color, HisaabColors.light.ink2);
      expect(tester.getTopLeft(find.text("You'll see exactly what it gets.")).dy, greaterThan(tester.getBottomLeft(find.text('Ask an AI about October')).dy - 1));
      expect(tester.getTopLeft(find.text("You'll see exactly what it gets.")).dx, tester.getTopLeft(find.text('Ask an AI about October')).dx);
    });

    final List<(String, Size, double)> windows = <(String, Size, double)>[
      ('a 320dp phone at 1.5× text', TestWindows.smallPhone, 1.5),
      ('a phone at 1.5× text', TestWindows.phone, 1.5),
      ('a phone in landscape', TestWindows.phoneLandscape, 1),
      ('an unfolded foldable', TestWindows.foldableUnfolded, 1),
      ('a foldable in landscape', TestWindows.foldableLandscape, 1),
      ('a tablet', TestWindows.tablet, 1),
    ];
    for (final (String name, Size size, double scale) in windows) {
      testWidgets('nothing clips on $name', (WidgetTester tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: AskAiCard(cycleLabel: '26 Oct – 1 Nov', onPressed: () {}),
            ),
          ),
          size: size,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final Rect card = tester.getRect(find.byKey(const ValueKey<String>('ask-ai-card-surface')));
        for (final String text in <String>['Ask an AI about 26 Oct – 1 Nov', "You'll see exactly what it gets."]) {
          final Rect line = tester.getRect(find.text(text));
          expect(card.contains(line.topLeft) && card.contains(line.bottomRight - const Offset(1, 1)), isTrue, reason: text);
        }
      });
    }
  });
}
