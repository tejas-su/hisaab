import 'package:expense_tracker/core/widgets/keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Keypad (UI_DESIGN §5.3)', () {
    late List<String> pressed;

    Future<void> pump(WidgetTester tester) => pumpApp(
          tester,
          Scaffold(
            body: Keypad(
              onKey: (String key) => pressed.add(key),
              onBackspace: () => pressed.add('⌫'),
              onClear: () => pressed.add('clear'),
            ),
          ),
        );

    setUp(() => pressed = <String>[]);

    testWidgets('phone layout: 1-2-3 on top, then 00 · 0 · ⌫, never moving', (WidgetTester tester) async {
      await pump(tester);
      final double top = tester.getTopLeft(find.byKey(const ValueKey<String>('keypad-1'))).dy;
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('keypad-3'))).dy, top);
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('keypad-00'))).dy, greaterThan(top));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('keypad-00'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey<String>('keypad-0'))).dx),
      );
    });

    testWidgets('digit keys type, ⌫ deletes, long-press ⌫ clears', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-4')));
      await tester.tap(find.byKey(const ValueKey<String>('keypad-00')));
      await tester.tap(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      expect(pressed, <String>['4', '00', '⌫', 'clear']);
    });

    testWidgets('every key is a labelled button of at least 48dp', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
