import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/story_split_bar.dart';
import 'package:hisaab/spends/presentation/widgets/split_bar_painter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/pump_app.dart';

Entry _spent(int id, int rupees, {bool notLogged = false, EntryKind kind = EntryKind.spent, int category = SeedCategoryIds.food}) => Entry(
      id: id,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: category,
      date: SeptemberStory.september.start,
      createdAt: DateTime(2026, 9, 4),
      isNotLogged: notLogged,
    );

void main() {
  const SplitColours colours = (ink: Color(0xFF000000), ink2: Color(0xFF777777), soft: Color(0xFF888888), sunk: Color(0xFF333333), gap: Color(0xFF111111));

  group('StorySplitBar (BR-20 page 2)', () {
    testWidgets('keys Bills, Saved, Everyday and Left over with amounts', (WidgetTester tester) async {
      await pumpApp(tester, Scaffold(body: StorySplitBar(story: SeptemberStory.story())));
      for (final String text in <String>['Bills', '₹9,400', 'Saved', '₹1,000', 'Everyday', '₹30,200', 'Left over', '₹4,400']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('adds Not logged when there is a fix, and drops Saved at ₹0', (WidgetTester tester) async {
      final List<Entry> entries = <Entry>[
        ...SeptemberStory.septemberEntries().where((Entry e) => e.kind != EntryKind.saved),
        _spent(990, 4200, notLogged: true, category: SeedCategoryIds.notLogged),
      ];
      await pumpApp(tester, Scaffold(body: StorySplitBar(story: SeptemberStory.story(entries: entries))));
      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('₹4,200'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('₹1,200'), findsOneWidget);
    });

    testWidgets('past income it keys More than came in', (WidgetTester tester) async {
      final List<Entry> entries = <Entry>[...SeptemberStory.septemberEntries(), _spent(991, 7500)];
      await pumpApp(tester, Scaffold(body: StorySplitBar(story: SeptemberStory.story(entries: entries))));
      expect(find.text('More than came in'), findsOneWidget);
      expect(find.text('₹3,100'), findsOneWidget);
    });
  });

  group('SplitBarPainter', () {
    Future<void> paint(WidgetTester tester, SplitAmounts amounts) => tester.pumpWidget(
          Center(child: SizedBox(width: 300, height: 28, child: CustomPaint(painter: SplitBarPainter(amounts: amounts, colours: colours)))),
        );

    testWidgets('paints under, over and empty bars without error', (WidgetTester tester) async {
      await paint(tester, (bills: 940000, saved: 100000, everyday: 3020000, income: 4500000));
      await paint(tester, (bills: 940000, saved: 100000, everyday: 3770000, income: 4500000));
      await paint(tester, (bills: 0, saved: 0, everyday: 0, income: 0));
      await paint(tester, (bills: 0, saved: 100, everyday: 0, income: 4500000));
      expect(tester.takeException(), isNull);
    });

    test('repaints only when its inputs change', () {
      const SplitBarPainter a = SplitBarPainter(amounts: (bills: 1, saved: 2, everyday: 3, income: 4), colours: colours);
      expect(a.shouldRepaint(const SplitBarPainter(amounts: (bills: 1, saved: 2, everyday: 3, income: 4), colours: colours)), isFalse);
      expect(a.shouldRepaint(const SplitBarPainter(amounts: (bills: 1, saved: 2, everyday: 3, income: 5), colours: colours)), isTrue);
    });
  });
}
