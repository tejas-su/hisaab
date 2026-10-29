import 'package:expense_tracker/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // why: a bare transparent bar is black at alpha 0, which Material reads as a dark bar, so it
    // asked for white status icons on the light page (D96).
    for (final (ThemeMode mode, Brightness icons) in <(ThemeMode, Brightness)>[
      (ThemeMode.light, Brightness.dark),
      (ThemeMode.dark, Brightness.light),
    ]) {
      testWidgets('status-bar icons contrast with the page in $mode', (WidgetTester tester) async {
        await pumpApp(tester, SettingsPage(onOpenBills: () {}), themeMode: mode);
        final AnnotatedRegion<SystemUiOverlayStyle> bar = tester.widget(
          find.descendant(of: find.byType(AppBar), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );
        expect(bar.value.statusBarIconBrightness, icons);
      });
    }

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
