import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/widgets/category_tile.dart';
import 'package:expense_tracker/core/widgets/display_card.dart';
import 'package:expense_tracker/core/widgets/hisaab_chip.dart';
import 'package:expense_tracker/core/widgets/shake.dart';
import 'package:expense_tracker/core/widgets/wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CategoryTile', () {
    testWidgets('reads as "Food. Save", saves on tap and shows the ink flash', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: Row(
            children: <Widget>[
              Expanded(child: CategoryTile(icon: AppIcons.forKey('food'), label: 'Food', semanticLabel: 'Food. Save', onPressed: () => taps++)),
              Expanded(child: CategoryTile(icon: AppIcons.forKey('fun'), label: 'Fun', semanticLabel: 'Fun. Save', onPressed: null, flashed: true)),
            ],
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Food. Save'));
      expect(taps, 1);
      final Container flashed = tester.widget<Container>(
        find.descendant(of: find.widgetWithText(CategoryTile, 'Fun'), matching: find.byType(Container)).first,
      );
      expect((flashed.decoration! as ShapeDecoration).color, HisaabColors.light.ink);
      handle.dispose();
    });
  });

  group('HisaabChip', () {
    testWidgets('selected chips are ink and speak their detail', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Scaffold(
          body: Column(
            children: <Widget>[
              HisaabChip(label: 'Rent', detail: '₹8,200 on day 5', selected: true, icon: AppIcons.check, onPressed: () {}),
              HisaabChip(label: 'Today', icon: AppIcons.calendar, trailingIcon: AppIcons.dropdown, expand: true, onPressed: () {}),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Rent, ₹8,200 on day 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Today'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Shake', () {
    testWidgets('shakes when the trigger changes and returns to rest', (WidgetTester tester) async {
      final ValueNotifier<int> trigger = ValueNotifier<int>(0);
      addTearDown(trigger.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: trigger,
          builder: (BuildContext _, int value, Widget? _) => Shake(trigger: value, child: const Text('₹0')),
        ),
      );
      trigger.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.widget<Transform>(find.byType(Transform).first).transform.getTranslation().x, isNot(0));
      await tester.pumpAndSettle();
      expect(tester.widget<Transform>(find.byType(Transform).first).transform.getTranslation().x, closeTo(0, 1e-6));
    });

    testWidgets('stays still with reduced motion', (WidgetTester tester) async {
      final ValueNotifier<int> trigger = ValueNotifier<int>(0);
      addTearDown(trigger.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: trigger,
          builder: (BuildContext _, int value, Widget? _) => Shake(trigger: value, child: const Text('₹0')),
        ),
        reduceMotion: true,
      );
      trigger.value = 1;
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.widget<Transform>(find.byType(Transform).first).transform.getTranslation().x, 0);
    });
  });

  group('Wordmark', () {
    testWidgets('reads as the app name, once', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Scaffold(body: Wordmark()));
      expect(find.bySemanticsLabel('hisaab'), findsOneWidget);
      handle.dispose();
    });
  });

  group('DisplayCard', () {
    testWidgets('gets a hairline edge only in dark mode', (WidgetTester tester) async {
      await pumpApp(tester, const Scaffold(body: DisplayCard(child: Text('x'))), themeMode: ThemeMode.dark);
      final ShapeDecoration decoration =
          tester.widget<Container>(find.descendant(of: find.byType(DisplayCard), matching: find.byType(Container))).decoration!
              as ShapeDecoration;
      expect((decoration.shape as OutlinedBorder).side.color, HisaabColors.dark.hairline);
    });
  });
}
