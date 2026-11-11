import 'dart:ui';

import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/widgets/day_of_month_grid.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('DayOfMonthGrid', () {
    testWidgets('a tap picks its day', (WidgetTester tester) async {
      int? picked;
      await pumpApp(tester, Scaffold(body: DayOfMonthGrid(onDay: (int day) => picked = day)));
      await tester.tap(find.byKey(const ValueKey<String>('day-31')));
      expect(picked, 31);
    });

    testWidgets('marks the selected day as selected, lifted to control, with an ink dot (D118)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, Scaffold(body: DayOfMonthGrid(onDay: (int _) {}, selected: const Option<int>.of(29))));
      expect(tester.getSemantics(find.byKey(const ValueKey<String>('day-29'))).flagsCollection.isSelected, Tristate.isTrue);
      expect(tester.getSemantics(find.byKey(const ValueKey<String>('day-28'))).flagsCollection.isSelected, isNot(Tristate.isTrue));
      final Finder fill = find.descendant(of: find.byKey(const ValueKey<String>('day-29')), matching: find.byType(Container)).first;
      expect((tester.widget<Container>(fill).decoration! as ShapeDecoration).color, HisaabColors.light.control);
      expect(find.byKey(const ValueKey<String>('day-picked-dot')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('marks nothing by default', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: DayOfMonthGrid(onDay: (int _) {})));
      expect(find.byKey(const ValueKey<String>('day-picked-dot')), findsNothing);
    });
  });
}
