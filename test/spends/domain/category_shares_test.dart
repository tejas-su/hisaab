import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/category_shares.dart';
import 'package:expense_tracker/spends/domain/entities/category_spend.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ledger/categories.dart';

Entry _spent(int id, int rupees, int categoryId, {EntryKind kind = EntryKind.spent}) => Entry(
      id: id,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: categoryId,
      date: const CalendarDate(2026, 10, 10),
      createdAt: DateTime(2026, 10, 10),
    );

const int _shopping = 3;
const int _fun = 5;

void main() {
  group('CategoryShares.of (BR-13)', () {
    test('SPEC example: 36 / 30 / 15 / 13 / 6, biggest first, summing to 100', () {
      final List<CategorySpend> rows = CategoryShares.of(<Entry>[
        _spent(1, 1830, _fun),
        _spent(2, 4100, SeedCategoryIds.travel),
        _spent(3, 9840, SeedCategoryIds.food),
        _spent(4, 3600, _shopping),
        _spent(5, 8200, SeedCategoryIds.bills),
      ], seedCategories);
      expect(rows.map((CategorySpend r) => r.category.key), <String>['food', 'bills', 'travel', 'shopping', 'fun']);
      expect(rows.map((CategorySpend r) => r.percent), <int>[36, 30, 15, 13, 6]);
      expect(rows.first.spent, Money.fromMajor(9840));
    });

    test('Saved entries are not spending (D120)', () {
      final List<CategorySpend> rows = CategoryShares.of(<Entry>[
        _spent(1, 60, SeedCategoryIds.food),
        Entry(
          id: 2,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 10),
          createdAt: DateTime(2026, 10, 10),
        ),
      ], seedCategories);
      expect(rows.map((CategorySpend r) => r.category.key), <String>['food']);
    });

    test('adds up several entries in one category', () {
      final List<CategorySpend> rows =
          CategoryShares.of(<Entry>[_spent(1, 60, SeedCategoryIds.food), _spent(2, 40, SeedCategoryIds.food)], seedCategories);
      expect(rows.single.spent, Money.fromMajor(100));
      expect(rows.single.percent, 100);
    });

    test('three equal thirds give 34 / 33 / 33, the extra point to the first in grid order', () {
      final List<CategorySpend> rows = CategoryShares.of(<Entry>[
        _spent(1, 100, SeedCategoryIds.travel),
        _spent(2, 100, _shopping),
        _spent(3, 100, SeedCategoryIds.food),
      ], seedCategories);
      expect(rows.map((CategorySpend r) => r.category.key), <String>['food', 'travel', 'shopping']);
      expect(rows.map((CategorySpend r) => r.percent), <int>[34, 33, 33]);
    });

    test('a tiny category can round to 0% and the rest still sum to 100', () {
      final List<CategorySpend> rows =
          CategoryShares.of(<Entry>[_spent(1, 99999, SeedCategoryIds.food), _spent(2, 1, _fun)], seedCategories);
      expect(rows.map((CategorySpend r) => r.percent), <int>[100, 0]);
    });

    test('Got entries are not spending', () {
      expect(CategoryShares.of(<Entry>[_spent(1, 45000, SeedCategoryIds.salary, kind: EntryKind.got)], seedCategories), isEmpty);
    });

    test('no entries gives no rows', () {
      expect(CategoryShares.of(const <Entry>[], seedCategories), isEmpty);
    });

    test('an entry whose category is gone is left out', () {
      expect(CategoryShares.of(<Entry>[_spent(1, 100, 99)], seedCategories), isEmpty);
    });
  });
}
