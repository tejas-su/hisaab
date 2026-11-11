import 'dart:ui';

import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/extensions/build_context_extensions.dart';
import 'package:hisaab/core/widgets/category_tile.dart';
import 'package:hisaab/core/widgets/display_card.dart';
import 'package:hisaab/core/widgets/hisaab_chip.dart';
import 'package:hisaab/core/widgets/shake.dart';
import 'package:hisaab/core/widgets/wordmark.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/focus_helpers.dart';
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
    testWidgets('selected chips speak their detail', (WidgetTester tester) async {
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

    ShapeDecoration chipShape(WidgetTester tester, String label) => tester
        .widget<Container>(find.descendant(of: find.widgetWithText(HisaabChip, label), matching: find.byType(Container)).first)
        .decoration! as ShapeDecoration;

    testWidgets('on the page a chip rests as a control fill with no edge, one layer up like the cards (D100)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'EMI', onPressed: () {})));
      final ShapeDecoration shape = chipShape(tester, 'EMI');
      expect(shape.color, HisaabColors.light.control);
      expect((shape.shape as RoundedSuperellipseBorder).side, BorderSide.none);
      expect(find.byType(AppIcon), findsNothing);
    });

    testWidgets('pressed, a chip on the page steps to sunk (D97, D100)', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'EMI', onPressed: () {})));
      final TestGesture press = await tester.startGesture(tester.getCenter(find.text('EMI')));
      await tester.pump();
      expect(chipShape(tester, 'EMI').color, HisaabColors.light.sunk);
      await press.up();
    });

    testWidgets('light: a pick fills ink with page-coloured text and check (D100)', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'Rent', selected: true, onPressed: () {})));
      expect(chipShape(tester, 'Rent').color, HisaabColors.light.ink);
      expect(tester.widget<Text>(find.text('Rent')).style?.color, HisaabColors.light.background);
      final AppIcon check = tester.widget<AppIcon>(find.byType(AppIcon));
      expect((check.icon, check.color), (AppIcons.check, HisaabColors.light.background));
    });

    testWidgets('dark: a pick fills ink with page-coloured text and check (D100)', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: HisaabChip(label: 'Rent', selected: true, onPressed: () {})),
        themeMode: ThemeMode.dark,
      );
      expect(chipShape(tester, 'Rent').color, HisaabColors.dark.ink);
      expect(tester.widget<Text>(find.text('Rent')).style?.color, HisaabColors.dark.background);
    });

    testWidgets('a focused pick keeps its ink fill and gains the ring; focus is never shown as selection (D99, D100)', (
      WidgetTester tester,
    ) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'Rent', selected: true, onPressed: () {})));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(chipShape(tester, 'Rent').color, HisaabColors.light.ink);
      expect(
        focusRingPaint(find.byType(HisaabChip)),
        paints
          ..path(color: HisaabColors.light.focusGap)
          ..path(color: HisaabColors.light.focus),
      );
    });

    testWidgets('a focused chip that is not picked keeps its control fill (D99, D100)', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'EMI', onPressed: () {})));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(chipShape(tester, 'EMI').color, HisaabColors.light.control);
      expect(showsFocusRing(tester, find.byType(HisaabChip)), isTrue);
    });

    for (final (ThemeMode mode, HisaabColors colors) in <(ThemeMode, HisaabColors)>[
      (ThemeMode.light, HisaabColors.light),
      (ThemeMode.dark, HisaabColors.dark),
    ]) {
      testWidgets('${mode.name}: a chip on the page is control; a chip on a surface layer is hairline (D100)', (
        WidgetTester tester,
      ) async {
        await pumpApp(
          tester,
          Scaffold(
            body: Column(
              children: <Widget>[
                HisaabChip(label: 'Page', onPressed: () {}),
                HisaabChip(label: 'Card', onSurface: true, onPressed: () {}),
              ],
            ),
          ),
          themeMode: mode,
        );
        expect(chipShape(tester, 'Page').color, colors.control);
        expect(chipShape(tester, 'Card').color, colors.hairline);
      });
    }

    testWidgets('pressed, a chip on a surface layer keeps its hairline fill and only shrinks (D100)', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'EMI', onSurface: true, onPressed: () {})));
      final TestGesture press = await tester.startGesture(tester.getCenter(find.text('EMI')));
      await tester.pump();
      expect(chipShape(tester, 'EMI').color, HisaabColors.light.hairline);
      await press.up();
    });

    testWidgets('a pick on a surface layer is ink too (D100)', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'Rent', selected: true, onSurface: true, onPressed: () {})));
      expect(chipShape(tester, 'Rent').color, HisaabColors.light.ink);
    });

    testWidgets('a disabled chip on a surface layer has no fill either', (WidgetTester tester) async {
      await pumpApp(tester, const Scaffold(body: HisaabChip(label: 'Copy only', onSurface: true, onPressed: null)));
      expect(chipShape(tester, 'Copy only').color, isNull);
    });

    testWidgets('a pick that already shows an icon gets no second check', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: HisaabChip(label: 'Rent', selected: true, icon: AppIcons.check, onPressed: () {})));
      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('a disabled chip has no fill', (WidgetTester tester) async {
      await pumpApp(tester, const Scaffold(body: HisaabChip(label: 'Copy only', onPressed: null)));
      expect(chipShape(tester, 'Copy only').color, isNull);
    });

    testWidgets('a chip without onPressed is disabled and greyed', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Scaffold(body: HisaabChip(label: 'Copy only', onPressed: null)));
      expect(tester.getSemantics(find.bySemanticsLabel('Copy only')).flagsCollection.isEnabled, Tristate.isFalse);
      final Text label = tester.widget<Text>(find.text('Copy only'));
      final BuildContext context = tester.element(find.text('Copy only'));
      expect(label.style?.color, context.colors.ink2);
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
