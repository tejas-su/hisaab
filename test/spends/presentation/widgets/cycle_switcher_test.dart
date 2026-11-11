import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/spends/presentation/widgets/cycle_switcher.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('a pressed arrow darkens its well, and a tap calls back', (WidgetTester tester) async {
    int earlier = 0;
    await pumpApp(tester, Scaffold(body: Center(child: CycleSwitcher(label: 'October', onEarlier: () => earlier++, onLater: null))));
    final Finder arrow = find.byKey(const ValueKey<String>('earlier-cycle'));
    final TestGesture press = await tester.startGesture(tester.getCenter(arrow));
    await tester.pump();
    final ShapeDecoration well = tester
        .widgetList<Container>(find.descendant(of: arrow, matching: find.byType(Container)))
        .map((Container c) => c.decoration)
        .whereType<ShapeDecoration>()
        .first;
    expect(well.color, HisaabColors.light.hairline);
    await press.up();
    await tester.pumpAndSettle();
    expect(earlier, 1);
  });
}
