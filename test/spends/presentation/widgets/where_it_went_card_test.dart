import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/category_spend.dart';
import 'package:hisaab/spends/presentation/widgets/limit_bar_painter.dart';
import 'package:hisaab/spends/presentation/widgets/where_it_went_card.dart';
import 'package:material_ui/material_ui.dart';
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
  late int seeAllTaps;

  setUp(() => seeAllTaps = 0);

  Future<void> pump(WidgetTester tester, List<CategorySpend> rows, {Size size = TestWindows.phone, double textScale = 1}) => pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: WhereItWentCard(rows: rows, cycleLabel: 'October', onSeeAll: () => seeAllTaps++),
          ),
        ),
        size: size,
        textScale: textScale,
      );

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
  group('WhereItWentCard See all (FR-SP-6)', () {
    final Finder seeAll = find.byKey(const ValueKey<String>('see-every-entry'));
    final List<CategorySpend> rows = <CategorySpend>[
      _row(1, 'food', spent: 5000, percent: 55),
      _row(2, 'travel', spent: 4100, percent: 45),
    ];

    testWidgets('sits on the title row and opens every entry', (WidgetTester tester) async {
      await pump(tester, rows);
      expect(find.text('See all'), findsOneWidget);
      expect(tester.getBottomLeft(seeAll).dy, lessThan(tester.getTopLeft(find.text('Food')).dy));
      await tester.tap(seeAll);
      expect(seeAllTaps, 1);
    });

    testWidgets('its label ends on the rows\' content edge, the title on the left one', (WidgetTester tester) async {
      await pump(tester, rows);
      final Rect card = tester.getRect(find.byType(WhereItWentCard));
      expect(tester.getTopRight(find.text('See all')).dx, card.right - 20);
      expect(tester.getTopLeft(find.text('Where it went')).dx, card.left + 20);
    });

    testWidgets('shares the title\'s baseline', (WidgetTester tester) async {
      await pump(tester, rows);
      expect(tester.getBottomLeft(find.text('See all')).dy, closeTo(tester.getBottomLeft(find.text('Where it went')).dy, 4));
    });

    testWidgets('is at least a 48dp target', (WidgetTester tester) async {
      await pump(tester, rows);
      expect(tester.getSize(seeAll).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(seeAll).width, greaterThanOrEqualTo(48));
    });

    testWidgets('TalkBack names the cycle it opens', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, rows);
      expect(find.bySemanticsLabel('Every entry in October'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a 320dp phone at 2× text wraps the title, never overflows', (WidgetTester tester) async {
      await pump(tester, rows, size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('See all'), findsOneWidget);
    });
  });
}
