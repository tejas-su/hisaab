import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
