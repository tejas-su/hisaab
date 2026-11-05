import 'package:expense_tracker/core/design/hisaab_dimensions.dart';
import 'package:expense_tracker/settings/presentation/pages/remind_ask_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<Future<Option<bool>>> open(WidgetTester tester, {Size size = TestWindows.phone}) async {
    await pumpApp(tester, const Scaffold(), size: size);
    final Future<Option<bool>> answer = RemindAskSheet.show(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    return answer;
  }

  group('RemindAskSheet (spec §5, D126)', () {
    testWidgets('asks the question with Remind me and Not now', (WidgetTester tester) async {
      await open(tester);
      expect(find.text("Remind you on the day it's due?"), findsOneWidget);
      expect(find.text('Remind me'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('Remind me answers yes and closes', (WidgetTester tester) async {
      final Future<Option<bool>> answer = await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('remind-yes')));
      await tester.pumpAndSettle();
      expect(find.byType(RemindAskSheet), findsNothing);
      expect(await answer, const Option<bool>.of(true));
    });

    testWidgets('Not now answers no', (WidgetTester tester) async {
      final Future<Option<bool>> answer = await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('remind-no')));
      await tester.pumpAndSettle();
      expect(await answer, const Option<bool>.of(false));
    });

    testWidgets('Back gives no answer, so it can be asked again', (WidgetTester tester) async {
      final Future<Option<bool>> answer = await open(tester);
      Navigator.of(tester.element(find.byType(RemindAskSheet))).pop();
      await tester.pumpAndSettle();
      expect(await answer, const Option<bool>.none());
    });

    testWidgets('the question starts on the page gutter', (WidgetTester tester) async {
      await open(tester);
      final double sheet = tester.getTopLeft(find.byType(RemindAskSheet)).dx;
      expect(tester.getTopLeft(find.text("Remind you on the day it's due?")).dx - sheet, HisaabSpacing.gutter);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final Size size in <Size>[
      TestWindows.phone,
      TestWindows.phoneLandscape,
      TestWindows.smallPhone,
      TestWindows.foldableUnfolded,
      TestWindows.foldableLandscape,
      TestWindows.tablet,
    ]) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()}', (WidgetTester tester) async {
        await open(tester, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
