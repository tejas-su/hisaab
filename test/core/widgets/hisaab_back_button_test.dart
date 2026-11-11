import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/widgets/hisaab_back_button.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/tooltip_finder.dart';
import '../../helpers/focus_helpers.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('HisaabBackButton (D57, D80)', () {
    Future<void> pushScreen(WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => Scaffold(
                      appBar: AppBar(
                        leadingWidth: HisaabBackButton.leadingWidth,
                        leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
                        title: const Text('Pushed'),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    final Finder well = find.byKey(const ValueKey<String>('back-well'));

    testWidgets('pops the screen', (WidgetTester tester) async {
      await pushScreen(tester);
      await tester.tap(find.byType(HisaabBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Pushed'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('in an app bar, the 40dp control well sits on the gutter (D100)', (WidgetTester tester) async {
      await pushScreen(tester);
      expect(tester.getSize(well), const Size(40, 40));
      expect(tester.getTopLeft(well).dx, 20);
      expect((tester.widget<Container>(well).decoration! as ShapeDecoration).color, HisaabColors.light.control);
    });

    testWidgets('the well steps to sunk while pressed (D97, D100)', (WidgetTester tester) async {
      await pushScreen(tester);
      final TestGesture press = await tester.startGesture(tester.getCenter(well));
      // why: the tooltip's long-press competes for the pointer, so tap-down waits for the press timeout.
      await tester.pump(kPressTimeout);
      expect((tester.widget<Container>(well).decoration! as ShapeDecoration).color, HisaabColors.light.sunk);
      await press.cancel();
    });

    testWidgets('reads "Back" once and keeps the long-press tooltip', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pushScreen(tester);
      expect(findTooltip('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(tester.getSemantics(find.byType(HisaabBackButton)).tooltip, isEmpty);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('HisaabBackButton focus (D99)', () {
    testWidgets('the ring hugs the 40dp well, not the 48dp tap target', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, const Scaffold(body: Align(alignment: AlignmentDirectional.topStart, child: HisaabBackButton())));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        focusRingPaint(find.byType(HisaabBackButton)),
        paints
          ..path()
          ..path(includes: <Offset>[const Offset(-2.5, 24), const Offset(42.5, 24)], excludes: <Offset>[const Offset(44, 24)]),
      );
    });
  });
}
