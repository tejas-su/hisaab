import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/entities/category_spend.dart';
import 'package:expense_tracker/spends/presentation/widgets/limit_bar_painter.dart';
import 'package:expense_tracker/spends/presentation/widgets/where_it_went_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/pump_app.dart';

CategorySpend _row(int id, String key, {required int spent, int? limit, required int percent}) => CategorySpend(
      category: Category(
        id: id,
        key: key,
        iconKey: key,
        kind: EntryKind.spent,
        sort: id,
        limit: Option<int>.fromNullable(limit).map(Money.fromMajor),
      ),
      spent: Money.fromMajor(spent),
      percent: percent,
    );

void main() {
  Future<void> pump(WidgetTester tester, List<CategorySpend> rows) =>
      pumpApp(tester, Scaffold(body: SingleChildScrollView(child: WhereItWentCard(rows: rows))));

  final Finder key = find.byKey(const ValueKey<String>('hatch-key'));

  group('WhereItWentCard hatch key (FR-SP-4, BR-12)', () {
    testWidgets('a row past its limit shows one key line under the rows', (WidgetTester tester) async {
      await pump(tester, <CategorySpend>[
        _row(1, 'food', spent: 9840, limit: 9000, percent: 70),
        _row(2, 'travel', spent: 4100, percent: 30),
      ]);
      expect(key, findsOneWidget);
      expect(find.text('Striped part is over the limit.'), findsOneWidget);
      expect(tester.getTopLeft(key).dy, greaterThan(tester.getBottomLeft(find.text('Travel')).dy));
    });

    testWidgets('the swatch is a fully hatched limit bar', (WidgetTester tester) async {
      await pump(tester, <CategorySpend>[_row(1, 'food', spent: 9840, limit: 9000, percent: 100)]);
      final LimitBarPainter swatch = tester
          .widgetList<CustomPaint>(find.descendant(of: key, matching: find.byType(CustomPaint)))
          .map((CustomPaint paint) => paint.painter)
          .whereType<LimitBarPainter>()
          .single;
      expect(swatch.fill, 1);
      expect(swatch.limitAt, 0);
    });

    testWidgets('no row past its limit: no key', (WidgetTester tester) async {
      await pump(tester, <CategorySpend>[
        _row(1, 'food', spent: 5000, limit: 5000, percent: 55),
        _row(2, 'travel', spent: 4100, percent: 45),
      ]);
      expect(key, findsNothing);
    });

    testWidgets('the key describes a look, so TalkBack skips it', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, <CategorySpend>[_row(1, 'food', spent: 9840, limit: 9000, percent: 100)]);
      expect(find.bySemanticsLabel(RegExp('Striped')), findsNothing);
      handle.dispose();
    });
  });
}
