import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/entities/category_spend.dart';
import 'package:expense_tracker/spends/presentation/widgets/category_spend_row.dart';
import 'package:expense_tracker/spends/presentation/widgets/limit_bar_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/pump_app.dart';

CategorySpend _food({int spent = 9840, int? limit, int percent = 36}) => CategorySpend(
      category: Category(
        id: 1,
        key: 'food',
        iconKey: 'food',
        kind: EntryKind.spent,
        sort: 0,
        limit: Option<int>.fromNullable(limit).map(Money.fromMajor),
      ),
      spent: Money.fromMajor(spent),
      percent: percent,
    );

void main() {
  Future<void> pump(WidgetTester tester, CategorySpend row, {int biggest = 9840}) =>
      pumpApp(tester, Scaffold(body: CategorySpendRow(row: row, biggest: Money.fromMajor(biggest))));

  LimitBarPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.descendant(of: find.byType(CategorySpendRow), matching: find.byType(CustomPaint)))
      .map((CustomPaint paint) => paint.painter)
      .whereType<LimitBarPainter>()
      .single;

  group('CategorySpendRow (FR-SP-4, BR-12)', () {
    testWidgets('no limit: name, share, amount and a full bar for the biggest', (WidgetTester tester) async {
      await pump(tester, _food());
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('36%'), findsOneWidget);
      expect(find.text('₹9,840'), findsOneWidget);
      expect(painter(tester).fill, 1);
      expect(painter(tester).limitAt, isNull);
    });

    testWidgets('a smaller row\'s bar is sized against the biggest', (WidgetTester tester) async {
      await pump(tester, _food(spent: 4920), biggest: 9840);
      expect(painter(tester).fill, 0.5);
    });

    testWidgets('past its limit: "₹840 past limit" replaces the share, and the bar hatches past the tick', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, _food(limit: 9000));
      expect(find.textContaining('₹840 past limit'), findsOneWidget);
      expect(find.text('36%'), findsNothing);
      expect(painter(tester).limitAt, closeTo(9000 / 9840, 1e-9));
      expect(
        find.bySemanticsLabel('Food: 9,840 rupees, 36%, limit 9,000 rupees, 840 rupees past limit'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('under its limit: the share shows and the tick sits ahead of the fill', (WidgetTester tester) async {
      await pump(tester, _food(spent: 4000, limit: 5000), biggest: 9840);
      expect(find.text('36%'), findsOneWidget);
      expect(painter(tester).limitAt, closeTo(5000 / 9840, 1e-9));
    });

    testWidgets('a limit beyond the biggest bar gets no tick', (WidgetTester tester) async {
      await pump(tester, _food(limit: 12000));
      expect(painter(tester).limitAt, isNull);
    });
  });

  group('LimitBarPainter', () {
    const LimitBarPainter base =
        LimitBarPainter(fill: 1, limitAt: 0.9, ink: Color(0xFF000000), track: Color(0xFF111111), notch: Color(0xFF222222), tick: Color(0xFF333333));

    test('repaints only when an input changes', () {
      expect(base.shouldRepaint(base), isFalse);
      const List<LimitBarPainter> changed = <LimitBarPainter>[
        LimitBarPainter(fill: 0.5, limitAt: 0.9, ink: Color(0xFF000000), track: Color(0xFF111111), notch: Color(0xFF222222), tick: Color(0xFF333333)),
        LimitBarPainter(fill: 1, limitAt: null, ink: Color(0xFF000000), track: Color(0xFF111111), notch: Color(0xFF222222), tick: Color(0xFF333333)),
        LimitBarPainter(fill: 1, limitAt: 0.9, ink: Color(0xFF010101), track: Color(0xFF111111), notch: Color(0xFF222222), tick: Color(0xFF333333)),
        LimitBarPainter(fill: 1, limitAt: 0.9, ink: Color(0xFF000000), track: Color(0xFF121212), notch: Color(0xFF222222), tick: Color(0xFF333333)),
        LimitBarPainter(fill: 1, limitAt: 0.9, ink: Color(0xFF000000), track: Color(0xFF111111), notch: Color(0xFF232323), tick: Color(0xFF333333)),
        LimitBarPainter(fill: 1, limitAt: 0.9, ink: Color(0xFF000000), track: Color(0xFF111111), notch: Color(0xFF222222), tick: Color(0xFF343434)),
      ];
      for (final LimitBarPainter painter in changed) {
        expect(painter.shouldRepaint(base), isTrue);
      }
    });
  });
}
