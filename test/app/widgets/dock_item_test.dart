import 'package:hisaab/app/widgets/dock_item.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/focus_helpers.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('DockItem focus (D99)', () {
    Widget item({required bool selected, required VoidCallback onPressed}) => Scaffold(
      body: Center(
        child: DockItem(icon: AppIcons.home, label: 'Home', selected: selected, onPressed: onPressed),
      ),
    );

    testWidgets('keyboard focus draws the ring; the selected item keeps its sunk fill', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, item(selected: true, onPressed: () {}));
      final Size before = tester.getSize(find.byType(DockItem));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(DockItem)), isTrue);
      final Material fill = tester.widget<Material>(find.descendant(of: find.byType(DockItem), matching: find.byType(Material)));
      expect(fill.color, HisaabColors.light.sunk);
      expect(tester.getSize(find.byType(DockItem)), before);
    });

    testWidgets('focus adds no Material focus fill, so it never reads as a pick', (WidgetTester tester) async {
      await pumpApp(tester, item(selected: false, onPressed: () {}));
      expect(tester.widget<InkWell>(find.byType(InkWell)).focusColor, HisaabColors.light.clear);
    });

    testWidgets('touch mode: no ring', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTouch);
      await pumpApp(tester, item(selected: false, onPressed: () {}));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(DockItem)), isFalse);
    });

    testWidgets('Enter opens the destination, like a tap', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      int taps = 0;
      await pumpApp(tester, item(selected: false, onPressed: () => taps++));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
