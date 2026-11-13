import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/settings/presentation/widgets/bill_row.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/focus_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('BillRow typography (D68)', () {
    testWidgets('the bill name is Regular row text and the day a Regular caption', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: BillRow(bill: WorkedExample.rent, onEdit: () {}, onDelete: () {}, onThresholdReached: () {})),
      );
      final TextStyle? name = tester.widget<Text>(find.text('Rent')).style;
      expect(name?.fontWeight, FontWeight.w400);
      expect(name?.fontSize, 16);
      final Text when = tester.widget<Text>(find.textContaining('day 5'));
      expect(when.style?.fontWeight, FontWeight.w400);
    });
  });

  group('BillRow icon (D118)', () {
    testWidgets('shows the icon its name suggests', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: BillRow(bill: WorkedExample.electricity, onEdit: () {}, onDelete: () {}, onThresholdReached: () {})));
      expect(tester.widget<AppIcon>(find.byType(AppIcon)).icon, BillIcon.power.glyph);
    });

    testWidgets('shows a hand-picked icon', (WidgetTester tester) async {
      final RecurringRule picked = WorkedExample.rent.copyWith(icon: const Option<BillIcon>.of(BillIcon.society));
      await pumpApp(tester, Scaffold(body: BillRow(bill: picked, onEdit: () {}, onDelete: () {}, onThresholdReached: () {})));
      expect(tester.widget<AppIcon>(find.byType(AppIcon)).icon, BillIcon.society.glyph);
    });
  });

  group('BillRow focus (D99)', () {
    testWidgets('keyboard focus draws the ring inside the row, with no Material focus fill', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, Scaffold(body: BillRow(bill: WorkedExample.rent, onEdit: () {}, onDelete: () {}, onThresholdReached: () {})));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(BillRow)), isTrue);
      expect(tester.widget<InkWell>(find.byType(InkWell)).focusColor, HisaabColors.light.clear);
      expect(
        focusRingPaint(find.byType(BillRow)),
        paints
          ..path()
          ..path(excludes: <Offset>[const Offset(-0.5, 20)]),
      );
    });
  });

  group('BillRow amount (D123)', () {
    Future<void> pumpRow(WidgetTester tester, AmountMode mode) => pumpApp(
          tester,
          Scaffold(
            body: BillRow(
              bill: WorkedExample.electricity.copyWith(amountMode: mode),
              onEdit: () {},
              onDelete: () {},
              onThresholdReached: () {},
            ),
          ),
        );

    testWidgets('a fixed bill shows its amount as it is', (WidgetTester tester) async {
      await pumpRow(tester, AmountMode.fixed);
      expect(find.text('₹1,200'), findsOneWidget);
    });

    for (final AmountMode mode in <AmountMode>[AmountMode.varies, AmountMode.card]) {
      testWidgets('a ${mode.name} bill says about, on screen and to TalkBack', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpRow(tester, mode);
        expect(find.text('about ₹1,200'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Electricity, about 1,200 rupees, ')), findsOneWidget);
        handle.dispose();
      });
    }
  });
  group('BillRow set aside (AC-Y3)', () {
    Future<void> pumpSaving(WidgetTester tester, {Money? setAside, double textScale = 1}) => pumpApp(
          tester,
          Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: BillRow(
                bill: WorkedExample.insurance,
                setAside: setAside,
                onEdit: () {},
                onDelete: () {},
                onThresholdReached: () {},
              ),
            ),
          ),
          textScale: textScale,
        );

    final Finder thirdLine = find.byKey(const ValueKey<String>('set-aside'));
    // why: the Dismissible stretches the row to its parent's height, so the row's natural height is
    // the text block (or the 42dp icon, if taller) plus the 9dp padding above and below.
    double rowHeight(WidgetTester tester, {required bool hasThirdLine}) {
      final Finder lastLine = hasThirdLine ? thirdLine : find.text('Every month on day 5');
      final double block = tester.getBottomLeft(lastLine).dy - tester.getTopLeft(find.text('Insurance')).dy;
      return (block > 42 ? block : 42) + 18;
    }

    testWidgets('the third line shows above ₹0 only; the schedule line stays the second', (WidgetTester tester) async {
      await pumpSaving(tester, setAside: Money.fromMajor(4000));

      expect(find.text('₹4,000 set aside'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Every month on day 5')).dy, lessThan(tester.getTopLeft(thirdLine).dy));
    });

    testWidgets('no third line for ₹0 or for no figure', (WidgetTester tester) async {
      await pumpSaving(tester, setAside: Money.zero);
      expect(thirdLine, findsNothing);

      await pumpSaving(tester);
      expect(thirdLine, findsNothing);
    });

    for (final double scale in <double>[1, 1.5]) {
      testWidgets('the row is about 84dp with the third line and 64dp without, at $scale x text', (WidgetTester tester) async {
        await pumpSaving(tester, setAside: Money.fromMajor(4000), textScale: scale);
        final double withLine = rowHeight(tester, hasThirdLine: true);
        await pumpSaving(tester, textScale: scale);
        final double without = rowHeight(tester, hasThirdLine: false);

        expect(withLine, greaterThan(without));
        if (scale == 1) {
          expect(withLine, inInclusiveRange(76, 90));
          expect(without, inInclusiveRange(58, 70));
        }
      });
    }

    testWidgets('TalkBack reads the set-aside after the schedule', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpSaving(tester, setAside: Money.fromMajor(4000));

      expect(find.bySemanticsLabel(RegExp(r'Insurance, 1,000 rupees, .*, 4,000 rupees set aside')), findsOneWidget);
      handle.dispose();
    });
  });

}
