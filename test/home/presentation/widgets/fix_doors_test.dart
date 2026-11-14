import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/home/presentation/widgets/fix_foot_row.dart';
import 'package:hisaab/home/presentation/widgets/install_line_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

const List<(String, Size)> _windows = <(String, Size)>[
  ('phone', TestWindows.phone),
  ('smallPhone', TestWindows.smallPhone),
  ('splitScreen', TestWindows.splitScreen),
  ('splitScreenShort', TestWindows.splitScreenShort),
  ('phoneLandscape', TestWindows.phoneLandscape),
  ('landscape600', TestWindows.landscape600),
  ('book', TestWindows.book),
  ('tabletop', TestWindows.tabletop),
  ('foldableLandscape', TestWindows.foldableLandscape),
  ('tablet', TestWindows.tablet),
];

/// The two quiet doors into *Fix my number* on Home: the foot row and the install line (SPEC FR-HO-9,
/// FR-HO-3, FR-KS-1).
void main() {
  group('FixFootRow', () {
    int taps = 0;

    Widget row() => Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: FixFootRow(onTap: () => taps++)));

    setUp(() => taps = 0);

    testWidgets('is plain ink2 text: no fill, no icon, no second line, 48dp or more', (WidgetTester tester) async {
      await pumpApp(tester, row());

      expect(find.text('Fix my number'), findsOneWidget);
      expect(find.descendant(of: find.byType(FixFootRow), matching: find.byType(AppIcon)), findsNothing);
      expect(find.descendant(of: find.byType(FixFootRow), matching: find.byType(Text)), findsOneWidget);
      expect(tester.getSize(find.byType(FixFootRow)).height >= 48, isTrue);
    });

    testWidgets('a tap calls onTap once', (WidgetTester tester) async {
      await pumpApp(tester, row());

      await tester.tap(find.text('Fix my number'));

      expect(taps, 1);
    });

    for (final (String, Size) window in _windows) {
      for (final double scale in <double>[1, 1.5, 2]) {
        testWidgets('${window.$1} at ${scale}x: no overflow', (WidgetTester tester) async {
          await pumpApp(tester, row(), size: window.$2, textScale: scale);

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('meets the tap target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, row());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('InstallLineRow', () {
    int taps = 0;

    Widget row({String period = 'month'}) => Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: InstallLineRow(period: period, onTap: () => taps++)));

    setUp(() => taps = 0);

    testWidgets('says "Already spent some this month?" over "Fix my number"', (WidgetTester tester) async {
      await pumpApp(tester, row());

      expect(find.text('Already spent some this month?'), findsOneWidget);
      expect(find.text('Fix my number'), findsOneWidget);
      expect(find.byWidgetPredicate((Widget w) => w is AppIcon && w.icon == AppIcons.fixMyNumber), findsOneWidget);
    });

    testWidgets('a weekly cycle says this week', (WidgetTester tester) async {
      await pumpApp(tester, row(period: 'week'));

      expect(find.text('Already spent some this week?'), findsOneWidget);
    });

    testWidgets('is one TalkBack node with the hint "Opens the keypad."', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, row());

      final SemanticsData data = tester.getSemantics(find.byType(InstallLineRow)).getSemanticsData();
      expect(data.label, 'Already spent some this month? Fix my number');
      expect(data.hint, 'Opens the keypad.');
      handle.dispose();
    });

    testWidgets('a tap calls onTap once', (WidgetTester tester) async {
      await pumpApp(tester, row());

      await tester.tap(find.byType(InstallLineRow));

      expect(taps, 1);
    });

    for (final (String, Size) window in _windows) {
      for (final double scale in <double>[1, 1.5, 2]) {
        testWidgets('${window.$1} at ${scale}x: no overflow, 56dp or more', (WidgetTester tester) async {
          await pumpApp(tester, row(), size: window.$2, textScale: scale);

          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(InstallLineRow)).height >= 56, isTrue);
        });
      }
    }

    testWidgets('meets the tap target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, row());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
