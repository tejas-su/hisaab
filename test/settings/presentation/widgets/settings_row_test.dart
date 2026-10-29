import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/settings/presentation/widgets/settings_row.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/focus_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('SettingsRow typography (D68)', () {
    testWidgets('the label is Regular row text', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: SettingsRow(icon: AppIcons.recurring, label: 'Fixed bills', onTap: () {})));
      final TextStyle? label = tester.widget<Text>(find.text('Fixed bills')).style;
      expect(label?.fontWeight, FontWeight.w400);
      expect(label?.fontSize, 16);
    });
  });

  group('SettingsRow focus (D99)', () {
    testWidgets('keyboard focus draws the ring inside the row, with no Material focus fill', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, Scaffold(body: SettingsRow(icon: AppIcons.recurring, label: 'Fixed bills', onTap: () {})));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(SettingsRow)), isTrue);
      expect(tester.widget<InkWell>(find.byType(InkWell)).focusColor, HisaabColors.light.clear);
      expect(
        focusRingPaint(find.byType(SettingsRow)),
        paints
          ..path()
          ..path(excludes: <Offset>[const Offset(-0.5, 20)]),
      );
    });
  });
}
