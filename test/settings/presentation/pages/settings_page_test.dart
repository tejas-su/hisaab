import 'package:expense_tracker/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('SettingsPage (FR-SE)', () {
    testWidgets('shows the Money group with Fixed bills, which opens', (WidgetTester tester) async {
      int opened = 0;
      await pumpApp(tester, SettingsPage(onOpenBills: () => opened++));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
      await tester.tap(find.text('Fixed bills'));
      expect(opened, 1);
    });

    testWidgets('lays out on a 320dp phone at 2× text', (WidgetTester tester) async {
      await pumpApp(tester, SettingsPage(onOpenBills: () {}), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, SettingsPage(onOpenBills: () {}));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
