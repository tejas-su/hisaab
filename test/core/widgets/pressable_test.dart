import 'package:expense_tracker/core/design/hisaab_motion.dart';
import 'package:expense_tracker/core/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
