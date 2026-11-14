import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/presentation/widgets/missed_log_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/pump_app.dart';

final MissedLog _foodLine = MissedLog(
  category: food,
  window: const TimeWindow(startMinute: 735, lengthMinutes: 105),
  amount: Money.fromMajor(55),
);

Widget _row({VoidCallback? onTap, MissedLog? line}) =>
    Scaffold(body: Column(children: <Widget>[MissedLogRow(line: line ?? _foodLine, onTap: onTap ?? () {})]));

ShapeDecoration _decoration(WidgetTester tester) => tester
    .widget<Container>(find.descendant(of: find.byType(MissedLogRow), matching: find.byType(Container)).first)
    .decoration! as ShapeDecoration;

void main() {
  group('MissedLogRow (FR-HO-3, D171)', () {
    testWidgets('shows the two lines and the neutral glyph, never the category glyph', (WidgetTester tester) async {
      await pumpApp(tester, _row());

      expect(find.text('Spent on Food today?'), findsOneWidget);
      expect(find.text('Usually around 1 pm.'), findsOneWidget);
      final List<AppIconData> glyphs = tester.widgetList<AppIcon>(find.byType(AppIcon)).map((AppIcon i) => i.icon).toList();
      expect(glyphs, <AppIconData>[AppIcons.questionLine, AppIcons.next]);
      expect(glyphs, isNot(contains(AppIcons.forKey(food.iconKey))));
    });

    testWidgets('shows no amount and no ×', (WidgetTester tester) async {
      await pumpApp(tester, _row());

      expect(find.textContaining('₹'), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('names a custom category without cutting it', (WidgetTester tester) async {
      await pumpApp(tester, _row(line: MissedLog(category: chai, window: _foodLine.window, amount: _foodLine.amount)));

      expect(find.text('Spent on Chai today?'), findsOneWidget);
    });

    testWidgets('is at least 56dp tall, and at 1.5x and 2x text a long name wraps and is not cut', (WidgetTester tester) async {
      const String longName = 'Evening snacks and chai with the neighbours';
      final MissedLog line = MissedLog(category: chai.copyWith(customName: longName), window: _foodLine.window, amount: _foodLine.amount);
      await pumpApp(tester, _row(line: line));
      expect(tester.getSize(find.byType(MissedLogRow)).height, greaterThanOrEqualTo(56));

      for (final double scale in <double>[1.5, 2]) {
        await pumpApp(tester, _row(line: line), size: TestWindows.smallPhone, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('Spent on $longName today?'), findsOneWidget);
        expect(tester.getSize(find.byType(MissedLogRow)).height, greaterThan(56));
      }
    });

    testWidgets('a tap, Enter and Space activate it', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, _row(onTap: () => taps++));

      await tester.tap(find.byType(MissedLogRow));
      expect(taps, 1);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 3);
    });

    testWidgets('rests on sunk, fills hairline while pressed, shows an ink2 outline when hovered', (WidgetTester tester) async {
      await pumpApp(tester, _row());
      final HisaabColors colors = Theme.of(tester.element(find.byType(MissedLogRow))).extension<HisaabColors>()!;
      expect(_decoration(tester).color, colors.sunk);
      expect((_decoration(tester).shape as OutlinedBorder).side, BorderSide.none);

      final TestGesture press = await tester.startGesture(tester.getCenter(find.byType(MissedLogRow)));
      await tester.pump();
      expect(_decoration(tester).color, colors.hairline);
      await press.up();
      await tester.pump();

      final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(5, 800));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(MissedLogRow)));
      await tester.pump();
      await tester.pump();
      expect((_decoration(tester).shape as OutlinedBorder).side, BorderSide(color: colors.ink2));
      await mouse.moveTo(const Offset(200, 400));
      await tester.pump();
      expect((_decoration(tester).shape as OutlinedBorder).side, BorderSide.none);
    });

    testWidgets('keyboard focus shows the outline too', (WidgetTester tester) async {
      await pumpApp(tester, _row());
      final HisaabColors colors = Theme.of(tester.element(find.byType(MissedLogRow))).extension<HisaabColors>()!;
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect((_decoration(tester).shape as OutlinedBorder).side, BorderSide(color: colors.ink2));
    });

    testWidgets('reads as one button, with the hint, and is not a live region', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _row());

      final node = tester.getSemantics(find.bySemanticsLabel('Spent on Food today? Usually around 1 pm.'));

      expect(
        node,
        isSemantics(
          label: 'Spent on Food today? Usually around 1 pm.',
          hint: 'Opens the keypad.',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(node.flagsCollection.isLiveRegion, isFalse);
      handle.dispose();
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _row());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('never uses marigold', (WidgetTester tester) async {
      await pumpApp(tester, _row());
      final HisaabColors colors = Theme.of(tester.element(find.byType(MissedLogRow))).extension<HisaabColors>()!;

      final Iterable<Color?> fills = tester
          .widgetList<Container>(find.descendant(of: find.byType(MissedLogRow), matching: find.byType(Container)))
          .map((Container c) => (c.decoration as ShapeDecoration?)?.color);

      expect(fills, isNot(contains(colors.signal)));
    });

    for (final (String, Size) window in <(String, Size)>[
      ('smallPhone', TestWindows.smallPhone),
      ('phone', TestWindows.phone),
      ('splitScreen', TestWindows.splitScreen),
      ('foldableUnfolded', TestWindows.foldableUnfolded),
      ('tablet', TestWindows.tablet),
    ]) {
      testWidgets('fits inside its window at ${window.$1}', (WidgetTester tester) async {
        await pumpApp(tester, _row(), size: window.$2);

        expect(tester.takeException(), isNull);
        final Rect rect = tester.getRect(find.byType(MissedLogRow));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(window.$2.width));
      });
    }
  });
}
