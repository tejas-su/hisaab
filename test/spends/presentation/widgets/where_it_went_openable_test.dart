import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/category_detail.dart';
import 'package:hisaab/spends/domain/entities/category_spend.dart';
import 'package:hisaab/spends/presentation/spends_graph_copy.dart';
import 'package:hisaab/spends/presentation/widgets/category_detail_panel.dart';
import 'package:hisaab/spends/presentation/widgets/where_it_went_card.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/pump_app.dart';

Money _r(int rupees) => Money.fromMajor(rupees);

Entry _entry(int id, int rupees, int day, {String? note}) => Entry(
      id: id,
      amount: _r(rupees),
      kind: EntryKind.spent,
      categoryId: SeedCategoryIds.food,
      date: CalendarDate(2026, 10, day),
      createdAt: DateTime(2026, 10, day),
      note: note,
    );

void main() {
  final List<CategorySpend> rows = <CategorySpend>[
    CategorySpend(category: seedCategories[0], spent: _r(9840), percent: 70),
    CategorySpend(category: seedCategories[1], spent: _r(4100), percent: 30),
  ];
  final Map<int, CategoryDetail> details = <int, CategoryDetail>{
    SeedCategoryIds.food: CategoryDetail(
      change: Option<Money>.of(_r(1200)),
      top: <Entry>[_entry(1, 2400, 20, note: 'Dinner out'), _entry(2, 1850, 12, note: 'Groceries'), _entry(3, 960, 8)],
      count: 21,
    ),
    SeedCategoryIds.travel: CategoryDetail(change: Option<Money>.of(_r(-900)), top: <Entry>[_entry(4, 4100, 15, note: 'Train')], count: 1),
  };
  late List<int> seen;

  setUp(() => seen = <int>[]);

  Future<void> pump(WidgetTester tester, {bool withChange = true, double textScale = 1}) => pumpApp(
        tester,
        Scaffold(
          body: ListView(
            children: <Widget>[
              WhereItWentCard(
                rows: rows,
                cycleLabel: 'October',
                onSeeAll: () {},
                details: details,
                changeOf: withChange ? (Money change) => (shown: 'change ${change.floorMajor}', spoken: 'spoken change ${change.floorMajor}', arrow: null) : null,
                onSeeCategory: seen.add,
              ),
            ],
          ),
        ),
        textScale: textScale,
      );

  group('WhereItWentCard with details (FR-SP-4 AC-R1, AC-R2)', () {
    testWidgets('a headline names the biggest; no row is open to start', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('The most went on Food.'), findsOneWidget);
      expect(find.byType(CategoryDetailPanel), findsNothing);
    });

    testWidgets('tapping a row opens it: change, caption, entries and See Food entries', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.text('change 1200'), findsOneWidget);
      expect(find.text('Biggest 3 of 21'), findsOneWidget);
      expect(find.textContaining('Dinner out', findRichText: true), findsOneWidget);
      expect(find.textContaining('No note', findRichText: true), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('see-category-entries')));
      expect(seen, <int>[SeedCategoryIds.food]);
    });

    testWidgets('one row open at a time; tapping it again closes it', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Travel'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey<String>('detail-${SeedCategoryIds.food}')), findsNothing);
      expect(find.text('Only entry'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('see-category-entries')), findsNothing);
      await tester.tap(find.text('Travel'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryDetailPanel), findsNothing);
    });

    testWidgets('without a comparison there is no change line', (WidgetTester tester) async {
      await pump(tester, withChange: false);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.textContaining('change'), findsNothing);
    });

    testWidgets('TalkBack: a button with an expanded state, the change read while open', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester);
      expect(
        tester.getSemantics(find.text('Food')),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false, hasTapAction: true, hint: 'Show biggest entries'),
      );
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.text('Food')), isSemantics(isExpanded: true, hint: 'Hide biggest entries'));
      expect(find.bySemanticsLabel(RegExp('spoken change 1200')), findsOneWidget);
      expect(find.bySemanticsLabel('Dinner out, 20 Oct, 2,400 rupees'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('at 1.3× text and above the icon wells drop', (WidgetTester tester) async {
      await pump(tester, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.byType(Container).evaluate().where((Element e) => (e.widget as Container).constraints?.maxWidth == 36), isEmpty);
    });

    testWidgets('a category with exactly 3 entries says All 3 entries; two say Both entries', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: CategoryDetailPanel(
            detail: CategoryDetail(change: const Option<Money>.none(), top: <Entry>[_entry(1, 30, 1), _entry(2, 20, 2), _entry(3, 10, 3)], count: 3),
            categoryName: 'Food',
            change: null,
            onSeeAll: () {},
          ),
        ),
      );
      expect(find.text('All 3 entries'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('see-category-entries')), findsNothing);
      await pumpApp(
        tester,
        Scaffold(
          body: CategoryDetailPanel(
            detail: CategoryDetail(change: const Option<Money>.none(), top: <Entry>[_entry(1, 30, 1), _entry(2, 20, 2)], count: 2),
            categoryName: 'Food',
            change: (shown: 'x', spoken: 'x', arrow: null) as ComparisonWords?,
            onSeeAll: null,
          ),
        ),
      );
      expect(find.text('Both entries'), findsOneWidget);
    });
  });
}
