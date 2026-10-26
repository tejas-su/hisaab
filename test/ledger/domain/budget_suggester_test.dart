import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/domain/budget_suggester.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ledger/categories.dart';

Entry _entry(int id, Money amount, int categoryId, {EntryKind kind = EntryKind.spent}) => Entry(
      id: id,
      amount: amount,
      kind: kind,
      categoryId: categoryId,
      date: const CalendarDate(2026, 10, 10),
      createdAt: DateTime(2026, 10, 10, 9),
    );

Money _rupees(int rupees) => Money.fromMajor(rupees);

void main() {
  group('BudgetSuggester.suggest (BR-12)', () {
    test('sums each category\'s spending and rounds it up to the next ₹500', () {
      final Map<int, Money> limits = BudgetSuggester.suggest(<Entry>[
        _entry(1, _rupees(6000), SeedCategoryIds.food),
        _entry(2, _rupees(3840), SeedCategoryIds.food),
        _entry(3, _rupees(4100), SeedCategoryIds.travel),
        _entry(4, _rupees(8200), SeedCategoryIds.home),
      ]);
      expect(limits, <int, Money>{
        SeedCategoryIds.food: _rupees(10000),
        SeedCategoryIds.travel: _rupees(4500),
        SeedCategoryIds.home: _rupees(8500),
      });
    });

    final List<(String, Money, Money)> rounding = <(String, Money, Money)>[
      ('exactly ₹500 stays', _rupees(500), _rupees(500)),
      ('₹501 goes to ₹1,000', _rupees(501), _rupees(1000)),
      ('₹1 goes to ₹500', _rupees(1), _rupees(500)),
      ('one paisa over ₹500 goes to ₹1,000', const Money(50001), _rupees(1000)),
      ('the 9-digit cap rounds past it', _rupees(999999999), _rupees(1000000000)),
    ];
    for (final (String name, Money spent, Money limit) in rounding) {
      test('rounding: $name', () {
        expect(BudgetSuggester.suggest(<Entry>[_entry(1, spent, SeedCategoryIds.food)]), <int, Money>{
          SeedCategoryIds.food: limit,
        });
      });
    }

    test('money that came in is not spending', () {
      expect(
        BudgetSuggester.suggest(<Entry>[_entry(1, _rupees(45000), SeedCategoryIds.salary, kind: EntryKind.got)]),
        isEmpty,
      );
    });

    test('no entries suggests nothing', () {
      expect(BudgetSuggester.suggest(const <Entry>[]), isEmpty);
    });
  });
}
