import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/widgets/hisaab_back_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    testWidgets('in an app bar, the 40dp sunk well sits on the gutter', (WidgetTester tester) async {
      await pushScreen(tester);
      expect(tester.getSize(well), const Size(40, 40));
      expect(tester.getTopLeft(well).dx, 20);
      expect((tester.widget<Container>(well).decoration! as ShapeDecoration).color, HisaabColors.light.sunk);
    });

    testWidgets('the well darkens to hairline while pressed', (WidgetTester tester) async {
      await pushScreen(tester);
      final TestGesture press = await tester.startGesture(tester.getCenter(well));
      // why: the tooltip's long-press competes for the pointer, so tap-down waits for the press timeout.
      await tester.pump(kPressTimeout);
      expect((tester.widget<Container>(well).decoration! as ShapeDecoration).color, HisaabColors.light.hairline);
      await press.cancel();
    });

    testWidgets('reads "Back" once and keeps the long-press tooltip', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pushScreen(tester);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(tester.getSemantics(find.byType(HisaabBackButton)).tooltip, isEmpty);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
