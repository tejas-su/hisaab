import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/widgets/hisaab_chip.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/entities/insight.dart';
import 'package:expense_tracker/spends/presentation/widgets/insight_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final List<(String, Insight)> seeEntries = <(String, Insight)>[
    ('category up', CategoryUp(categoryId: SeedCategoryIds.food, rise: Money.fromMajor(1100))),
    ('biggest spend', BiggestSpend(categoryId: SeedCategoryIds.food, amount: Money.fromMajor(900), date: const CalendarDate(2026, 10, 7))),
    ('steadiest', const SteadiestCategory(categoryId: SeedCategoryIds.food)),
  ];
  for (final (String name, Insight insight) in seeEntries) {
    testWidgets('$name: See Food entries opens Food\'s entries', (WidgetTester tester) async {
      final List<int> opened = <int>[];
      await pumpApp(
        tester,
        Scaffold(
          body: InsightTile(
            insight: insight,
            categories: <int, Category>{for (final Category c in seedCategories) c.id: c},
            previousCycle: 'September',
            onSeeEntries: opened.add,
            onUseLimits: (LimitOffer _) => fail('not an offer'),
          ),
        ),
      );
      // why: the action now names the category too ("See Food entries").
      expect(find.textContaining('Food'), findsNWidgets(2));
      await tester.tap(find.text('See Food entries'));
      expect(opened, <int>[SeedCategoryIds.food]);
    });
  }

  testWidgets('its chip sits in the insights card, so it keeps the hairline step (D100)', (WidgetTester tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: InsightTile(
          insight: const SteadiestCategory(categoryId: SeedCategoryIds.food),
          categories: <int, Category>{for (final Category c in seedCategories) c.id: c},
          previousCycle: 'September',
          onSeeEntries: (int _) {},
          onUseLimits: (LimitOffer _) {},
        ),
      ),
    );
    expect(tester.widget<HisaabChip>(find.byType(HisaabChip)).onSurface, isTrue);
  });
}
