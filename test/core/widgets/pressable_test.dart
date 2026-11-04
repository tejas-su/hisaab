import 'package:expense_tracker/core/design/hisaab_motion.dart';
import 'package:expense_tracker/core/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/focus_helpers.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('Pressable', () {
    testWidgets('scales to 0.97 while held, back on release or cancel', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: Pressable(
              semanticLabel: 'Key',
              onPressed: () {},
              builder: (BuildContext _, bool pressed) => SizedBox.square(dimension: 60, child: Text(pressed ? 'down' : 'up')),
            ),
          ),
        ),
      );
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Pressable)));
      await tester.pumpAndSettle();
      expect(find.text('down'), findsOneWidget);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, HisaabMotion.pressedScale);
      await gesture.moveBy(const Offset(0, 300));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.text('up'), findsOneWidget);
    });

    testWidgets('announces a hint after its label when given one', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Scaffold(
          body: Pressable(
            semanticLabel: 'Electricity',
            semanticHint: 'Opens the bill.',
            onPressed: () {},
            builder: (BuildContext _, bool _) => const SizedBox(width: 48, height: 48),
          ),
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled: no press state, announced as disabled', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: Pressable(
              semanticLabel: 'Key',
              onPressed: null,
              selected: true,
              builder: (BuildContext _, bool pressed) => SizedBox.square(dimension: 60, child: Text(pressed ? 'down' : 'up')),
            ),
          ),
        ),
      );
      await tester.press(find.byType(Pressable));
      await tester.pump();
      expect(find.text('up'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(Pressable)),
        matchesSemantics(label: 'Key', isButton: true, hasEnabledState: true, hasSelectedState: true, isSelected: true),
      );
      handle.dispose();
    });
  });

  group('Pressable focus (UI_DESIGN §9, principle 24, D99)', () {
    Widget key({VoidCallback? onPressed, bool? selected}) => Scaffold(
          body: Center(
            child: Pressable(
              semanticLabel: 'Key',
              onPressed: onPressed,
              selected: selected,
              builder: (BuildContext _, bool pressed) => const SizedBox.square(dimension: 60),
            ),
          ),
        );

    testWidgets('Tab focuses it and draws the ring', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, key(onPressed: () {}));
      expect(showsFocusRing(tester, find.byType(Pressable)), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(Pressable)), isTrue);
    });

    testWidgets('touch mode: focused, but no ring', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTouch);
      await pumpApp(tester, key(onPressed: () {}));
      Focus.of(tester.element(find.byType(SizedBox).last)).requestFocus();
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.byType(SizedBox).last)).hasFocus, isTrue);
      expect(showsFocusRing(tester, find.byType(Pressable)), isFalse);
    });

    for (final LogicalKeyboardKey activator in <LogicalKeyboardKey>[
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.select,
    ]) {
      testWidgets('${activator.keyLabel.isEmpty ? activator.debugName : activator.keyLabel} runs the same onPressed as a tap', (
        WidgetTester tester,
      ) async {
        useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
        int taps = 0;
        await pumpApp(tester, key(onPressed: () => taps++));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(activator);
        await tester.pump();
        expect(taps, 1);
      });
    }

    testWidgets('disabled: Tab skips it and Enter does nothing', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, key());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(Pressable)), isFalse);
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('phone', TestWindows.phone),
      ('phoneLandscape', TestWindows.phoneLandscape),
      ('smallPhone', TestWindows.smallPhone),
      ('foldableUnfolded', TestWindows.foldableUnfolded),
      ('foldableLandscape', TestWindows.foldableLandscape),
      ('tablet', TestWindows.tablet),
    ]) {
      testWidgets('$name: focus changes neither its size nor its place', (WidgetTester tester) async {
        useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
        await pumpApp(tester, key(onPressed: () {}), size: size);
        final Rect before = tester.getRect(find.byType(Pressable));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(showsFocusRing(tester, find.byType(Pressable)), isTrue);
        expect(tester.getRect(find.byType(Pressable)), before);
      });
    }

    testWidgets('a11y: focus adds nothing to what TalkBack hears and keeps a 48dp target', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, key(onPressed: () {}, selected: true));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byType(Pressable)),
        matchesSemantics(
          label: 'Key',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
