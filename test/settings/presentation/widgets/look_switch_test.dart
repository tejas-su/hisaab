import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/settings/domain/entities/theme_choice.dart';
import 'package:hisaab/settings/presentation/widgets/look_switch.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/focus_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Widget lookSwitch() => Scaffold(body: Center(child: LookSwitch(picked: ThemeChoice.matchPhone, onPicked: (ThemeChoice _) {})));

  Color? fill(WidgetTester tester, String key) =>
      ((tester.widget<Container>(find.byKey(ValueKey<String>('look-$key'))).decoration as ShapeDecoration?)?.color);

  group('LookSwitch (FR-SE-3)', () {
    testWidgets('the pick fills ink; the others rest clear on the track', (WidgetTester tester) async {
      await pumpApp(tester, lookSwitch());
      expect(fill(tester, 'matchPhone'), HisaabColors.light.ink);
      expect(fill(tester, 'light'), isNull);
    });

    testWidgets('a held icon steps to hairline', (WidgetTester tester) async {
      await pumpApp(tester, lookSwitch());
      final TestGesture press = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<String>('look-light'))));
      await tester.pump();
      expect(fill(tester, 'light'), HisaabColors.light.hairline);
      await press.up();
    });

    testWidgets('keyboard focus draws the ring (D99)', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, lookSwitch());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byKey(const ValueKey<String>('look-track'))), isTrue);
    });
  });
}
