import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/focus_helpers.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('FocusRing (principle 24, D99)', () {
    final FocusNode node = FocusNode(debugLabel: 'target');
    tearDownAll(node.dispose);

    Widget ring({EdgeInsetsGeometry inset = EdgeInsets.zero}) => Scaffold(
          body: Center(
            child: FocusRing(
              inset: inset,
              child: Focus(focusNode: node, child: const SizedBox(width: 100, height: 60)),
            ),
          ),
        );

    testWidgets('keyboard focus draws the gap, then the ring, outside the control', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring());
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(Scaffold)), isTrue);
      expect(
        focusRingPaint(find.byType(Scaffold)),
        paints
          ..path(color: HisaabColors.light.focusGap, strokeWidth: FocusRing.gap)
          ..path(color: HisaabColors.light.focus, strokeWidth: FocusRing.width, includes: <Offset>[const Offset(-2.5, 30)]),
      );
    });

    testWidgets('dark: the ring and gap use the dark tokens', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring(), themeMode: ThemeMode.dark);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(
        focusRingPaint(find.byType(Scaffold)),
        paints
          ..path(color: HisaabColors.dark.focusGap)
          ..path(color: HisaabColors.dark.focus),
      );
    });

    testWidgets('an inset ring stays inside the control’s bounds, for rows in a clipped card', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring(inset: const EdgeInsets.all(FocusRing.outset)));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(
        focusRingPaint(find.byType(Scaffold)),
        paints
          ..path()
          ..path(includes: <Offset>[const Offset(1.5, 30)], excludes: <Offset>[const Offset(-0.5, 30)]),
      );
    });

    testWidgets('touch focus draws nothing', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTouch);
      await pumpApp(tester, ring());
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(showsFocusRing(tester, find.byType(Scaffold)), isFalse);
    });

    testWidgets('no ring without focus, and it goes the moment focus leaves', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring());
      expect(showsFocusRing(tester, find.byType(Scaffold)), isFalse);
      node.requestFocus();
      await tester.pumpAndSettle();
      node.unfocus();
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(Scaffold)), isFalse);
    });

    testWidgets('a touch after keyboard focus hides the ring; a key brings it back', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring());
      node.requestFocus();
      await tester.pumpAndSettle();
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      await tester.pump();
      expect(showsFocusRing(tester, find.byType(Scaffold)), isFalse);
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(showsFocusRing(tester, find.byType(Scaffold)), isTrue);
    });

    for (final (String change, double radius, EdgeInsetsGeometry inset) in <(String, double, EdgeInsetsGeometry)>[
      ('radius', 22, EdgeInsets.zero),
      ('inset', 12, const EdgeInsets.all(FocusRing.outset)),
    ]) {
      testWidgets('a $change change while focused redraws the ring', (WidgetTester tester) async {
        useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
        final ValueNotifier<(double, EdgeInsetsGeometry)> shape = ValueNotifier<(double, EdgeInsetsGeometry)>((12, EdgeInsets.zero));
        addTearDown(shape.dispose);
        await pumpApp(
          tester,
          Scaffold(
            body: Center(
              child: ValueListenableBuilder<(double, EdgeInsetsGeometry)>(
                valueListenable: shape,
                builder: (BuildContext _, (double, EdgeInsetsGeometry) value, Widget? child) =>
                    FocusRing(radius: value.$1, inset: value.$2, child: child ?? const SizedBox()),
                child: Focus(focusNode: node, child: const SizedBox(width: 100, height: 60)),
              ),
            ),
          ),
        );
        node.requestFocus();
        await tester.pumpAndSettle();
        shape.value = (radius, inset);
        await tester.pump();
        expect(focusRingPaint(find.byType(Scaffold)), paints..path()..path());
      });
    }

    testWidgets('a theme change while focused redraws the ring in the new tokens', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring());
      node.requestFocus();
      await tester.pumpAndSettle();
      await pumpApp(tester, ring(), themeMode: ThemeMode.dark);
      expect(
        focusRingPaint(find.byType(Scaffold)),
        paints
          ..path(color: HisaabColors.dark.focusGap)
          ..path(color: HisaabColors.dark.focus),
      );
    });

    testWidgets('the ring changes neither size nor layout', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, ring());
      final Rect before = tester.getRect(find.byType(FocusRing));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(FocusRing)), before);
      expect(before.size, const Size(100, 60));
    });
  });
}
