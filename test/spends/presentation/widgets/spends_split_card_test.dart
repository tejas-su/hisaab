import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/spends/domain/entities/money_split.dart';
import 'package:hisaab/spends/presentation/widgets/spends_split_card.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

Money _r(int rupees) => Money.fromMajor(rupees);

MoneySplit _split({int income = 45000, int bills = 8200, int saved = 1000, int everyday = 19370, int notLogged = 0}) =>
    MoneySplit(income: _r(income), bills: _r(bills), saved: _r(saved), everyday: _r(everyday), notLogged: _r(notLogged));

void main() {
  late int added;

  setUp(() => added = 0);

  Future<void> pump(WidgetTester tester, MoneySplit split, {bool running = true, bool weekly = false, Size size = TestWindows.phone, double textScale = 1}) =>
      pumpApp(
        tester,
        Scaffold(
          body: ListView(
            children: <Widget>[
              SpendsSplitCard(split: split, isRunning: running, cycleLabel: 'September', isWeekly: weekly, onAddIncome: () => added++),
            ],
          ),
        ),
        size: size,
        textScale: textScale,
      );

  group('SpendsSplitCard (FR-SP-4b, BR-21)', () {
    testWidgets('worked example: money in, the answer, saved, and two key rows', (WidgetTester tester) async {
      await pump(tester, _split());
      for (final String text in <String>['Money in ₹45,000', '₹16,430 not spent yet', 'And ₹1,000 saved.', 'Bills', '₹8,200', 'Everyday', '₹19,370', 'Everyday is all spending except bills.']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('TalkBack reads one node, the answer first', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester, _split());
      expect(
        find.bySemanticsLabel('16,430 rupees not spent yet of 45,000 rupees. Bills 8,200 rupees. Saved 1,000 rupees. Everyday 19,370 rupees.'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a finished cycle says left over', (WidgetTester tester) async {
      await pump(tester, _split(), running: false);
      expect(find.text('₹16,430 left over'), findsOneWidget);
    });

    testWidgets('past what came in: more than came in, and that includes the saving', (WidgetTester tester) async {
      await pump(tester, _split(everyday: 38900));
      expect(find.text('₹3,100 more than came in'), findsOneWidget);
      expect(find.text('That includes ₹1,000 saved.'), findsOneWidget);
    });

    testWidgets('exactly ₹0 left: all of it spent or saved, or nothing left over', (WidgetTester tester) async {
      await pump(tester, _split(everyday: 35800));
      expect(find.text('All of it is spent or saved.'), findsOneWidget);
      await pump(tester, _split(everyday: 35800), running: false);
      expect(find.text('Nothing left over.'), findsOneWidget);
    });

    testWidgets('no bills and no saving leave their rows and line out; Not logged joins the note', (WidgetTester tester) async {
      await pump(tester, _split(bills: 0, saved: 0, notLogged: 4200));
      expect(find.text('Bills'), findsNothing);
      expect(find.textContaining('saved'), findsNothing);
      expect(find.text('Everyday is all spending except bills, including ₹4,200 not logged.'), findsOneWidget);
      expect(find.text('₹23,570'), findsOneWidget);
    });

    testWidgets('no money in: the prompt and its chip, which opens Settings', (WidgetTester tester) async {
      await pump(tester, _split(income: 0));
      expect(find.text('Spending this month'), findsOneWidget);
      expect(find.text('Add the money coming in to see how it splits.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('add-money-in')));
      expect(added, 1);
      await pump(tester, _split(income: 0), running: false);
      expect(find.text('Spending in September'), findsOneWidget);
      await pump(tester, _split(income: 0), weekly: true);
      expect(find.text('Spending this week'), findsOneWidget);
    });

    testWidgets('holds at 2.0× text on a small phone', (WidgetTester tester) async {
      await pump(tester, _split(), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
