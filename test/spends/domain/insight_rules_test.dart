import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/entities/insight.dart';
import 'package:expense_tracker/spends/domain/insight_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fixtures/ledger/categories.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));
const PayCycle _september = PayCycle(start: CalendarDate(2026, 9, 4), end: CalendarDate(2026, 10, 3));
const CalendarDate _today = CalendarDate(2026, 10, 26);

int _id = 0;

Entry _spent(int rupees, int categoryId, CalendarDate date, {int? recurringId, EntryKind kind = EntryKind.spent}) => Entry(
      id: ++_id,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: categoryId,
      date: date,
      createdAt: DateTime(2026, 9, 1),
      recurringId: recurringId,
    );

CalendarDate _oct(int day) => CalendarDate(2026, 10, day);
CalendarDate _sep(int day) => CalendarDate(2026, 9, day);

List<Insight> _evaluate(List<Entry> current, {List<Entry>? previous, CalendarDate asOf = _today, PayCycle cycle = _october}) =>
    InsightRules.evaluate(
      InsightWindow(cycle: cycle, asOf: asOf, entries: current),
      previous: Option<List<Entry>>.fromNullable(previous)
          .map((List<Entry> entries) => InsightWindow(cycle: _september, asOf: _september.end, entries: entries)),
    );

void main() {
  group('InsightRules — #1 category up on last cycle (BR-14)', () {
    test('Food ₹3,000 by day 22 against ₹1,900 by day 22 last cycle: up ₹1,100', () {
      expect(
        _evaluate(<Entry>[_spent(3000, SeedCategoryIds.food, _oct(10))], previous: <Entry>[_spent(1900, SeedCategoryIds.food, _sep(10))]),
        <Insight>[CategoryUp(categoryId: SeedCategoryIds.food, rise: Money.fromMajor(1100))],
      );
    });

    test('last cycle\'s spending after the same day-of-cycle is not compared', () {
      final List<Insight> insights = _evaluate(
        <Entry>[_spent(3000, SeedCategoryIds.food, _oct(10))],
        previous: <Entry>[_spent(1900, SeedCategoryIds.food, _sep(10)), _spent(5000, SeedCategoryIds.food, _sep(30))],
      );
      expect(insights, contains(CategoryUp(categoryId: SeedCategoryIds.food, rise: Money.fromMajor(1100))));
    });

    test('day 31 of a cycle compares with the last day of a 30-day one', () {
      const PayCycle long = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 4));
      final List<Insight> insights = _evaluate(
        <Entry>[_spent(3000, SeedCategoryIds.food, _oct(10))],
        previous: <Entry>[_spent(1000, SeedCategoryIds.food, _oct(3))],
        cycle: long,
        asOf: long.end,
      );
      expect(insights.first, CategoryUp(categoryId: SeedCategoryIds.food, rise: Money.fromMajor(2000)));
    });

    final List<(String, int, int, bool)> thresholds = <(String, int, int, bool)>[
      ('exactly 20% and ₹1,000 up counts', 6000, 5000, true),
      ('₹1,000 up but under 20% does not', 7000, 6000, false),
      ('20% up but under ₹1,000 does not', 1200, 1000, false),
      ('nothing last cycle and ₹1,000 now counts', 1000, 0, true),
    ];
    for (final (String name, int now, int before, bool shown) in thresholds) {
      test(name, () {
        final List<Insight> insights = _evaluate(
          <Entry>[_spent(now, SeedCategoryIds.travel, _oct(10))],
          previous: before == 0 ? <Entry>[] : <Entry>[_spent(before, SeedCategoryIds.travel, _sep(10))],
        );
        expect(insights.whereType<CategoryUp>().isNotEmpty, shown);
      });
    }

    test('only the biggest rise is shown', () {
      final List<Insight> insights = _evaluate(
        <Entry>[_spent(5000, SeedCategoryIds.travel, _oct(10)), _spent(9000, SeedCategoryIds.food, _oct(10))],
        previous: <Entry>[],
      );
      expect(insights.whereType<CategoryUp>(), <CategoryUp>[CategoryUp(categoryId: SeedCategoryIds.food, rise: Money.fromMajor(9000))]);
    });

    test('without a tracked last cycle nothing is "up"', () {
      expect(_evaluate(<Entry>[_spent(9000, SeedCategoryIds.food, _oct(10))]).whereType<CategoryUp>(), isEmpty);
    });

    test('money that came in is never "up"', () {
      expect(
        _evaluate(<Entry>[_spent(45000, SeedCategoryIds.salary, _oct(4), kind: EntryKind.got)], previous: <Entry>[]),
        isEmpty,
      );
    });
  });

  group('InsightRules — #2 biggest spend (BR-14)', () {
    test('₹1,000 against a ₹100 median stands out', () {
      expect(
        _evaluate(<Entry>[
          _spent(100, SeedCategoryIds.food, _oct(5)),
          _spent(100, SeedCategoryIds.food, _oct(6)),
          _spent(1000, SeedCategoryIds.food, _oct(7)),
        ]),
        <Insight>[BiggestSpend(categoryId: SeedCategoryIds.food, amount: Money.fromMajor(1000), date: _oct(7))],
      );
    });

    test('exactly twice the median does not stand out', () {
      expect(
        _evaluate(<Entry>[
          _spent(100, SeedCategoryIds.food, _oct(5)),
          _spent(100, SeedCategoryIds.food, _oct(6)),
          _spent(200, SeedCategoryIds.food, _oct(7)),
        ]),
        isEmpty,
      );
    });

    test('an even count uses the middle pair: 100, 300 → median 200, so 401 stands out', () {
      final List<Insight> insights = _evaluate(<Entry>[
        _spent(100, SeedCategoryIds.travel, _oct(5)),
        _spent(300, SeedCategoryIds.travel, _oct(6)),
        _spent(300, SeedCategoryIds.travel, _oct(7)),
        _spent(401, SeedCategoryIds.travel, _oct(8)),
      ]);
      expect(insights.whereType<BiggestSpend>(), isEmpty, reason: 'median of 100, 300, 300, 401 is 300');
      final List<Insight> pair = _evaluate(<Entry>[
        _spent(100, SeedCategoryIds.travel, _oct(5)),
        _spent(300, SeedCategoryIds.travel, _oct(6)),
        _spent(401, SeedCategoryIds.travel, _oct(7)),
        _spent(100, SeedCategoryIds.travel, _oct(8)),
      ]);
      expect(
        pair.whereType<BiggestSpend>(),
        <BiggestSpend>[BiggestSpend(categoryId: SeedCategoryIds.travel, amount: Money.fromMajor(401), date: _oct(7))],
      );
    });

    test('a single entry never stands out against itself', () {
      expect(_evaluate(<Entry>[_spent(5000, SeedCategoryIds.food, _oct(5))]), isEmpty);
    });

    test('the biggest standout across categories wins', () {
      final List<Insight> insights = _evaluate(<Entry>[
        _spent(10, SeedCategoryIds.food, _oct(5)),
        _spent(10, SeedCategoryIds.food, _oct(6)),
        _spent(500, SeedCategoryIds.food, _oct(7)),
        _spent(10, SeedCategoryIds.travel, _oct(5)),
        _spent(10, SeedCategoryIds.travel, _oct(6)),
        _spent(900, SeedCategoryIds.travel, _oct(8)),
      ]);
      expect(insights.single, BiggestSpend(categoryId: SeedCategoryIds.travel, amount: Money.fromMajor(900), date: _oct(8)));
    });

    test('bills posted by a rule and entries after the as-of day are left out', () {
      expect(
        _evaluate(<Entry>[
          _spent(100, SeedCategoryIds.home, _oct(5)),
          _spent(100, SeedCategoryIds.home, _oct(6)),
          _spent(8200, SeedCategoryIds.home, _oct(7), recurringId: 2),
          _spent(9000, SeedCategoryIds.home, _oct(27)),
        ]),
        isEmpty,
      );
    });
  });

  group('InsightRules — #3 steadiest category (BR-14)', () {
    // Whole weeks before 26 Oct: 4–10, 11–17 and 18–24 Oct.
    List<Entry> weekly(int categoryId, List<int> rupees) => <Entry>[
          for (final (int week, int amount) in rupees.indexed) ...<Entry>[
            _spent(amount ~/ 2, categoryId, _oct(4 + week * 7)),
            _spent(amount - amount ~/ 2, categoryId, _oct(5 + week * 7)),
          ],
        ];

    test('the category with the most even weeks, relative to its size, is steadiest', () {
      expect(
        _evaluate(<Entry>[...weekly(SeedCategoryIds.travel, <int>[1000, 1000, 1100]), ...weekly(SeedCategoryIds.food, <int>[10, 30, 20])]),
        <Insight>[const SteadiestCategory(categoryId: SeedCategoryIds.travel)],
      );
    });

    test('equally steady: the bigger total wins', () {
      expect(
        _evaluate(<Entry>[...weekly(SeedCategoryIds.travel, <int>[100, 100, 100]), ...weekly(SeedCategoryIds.food, <int>[200, 200, 200])]),
        <Insight>[const SteadiestCategory(categoryId: SeedCategoryIds.food)],
      );
    });

    test('fewer than 4 entries is not enough', () {
      expect(_evaluate(<Entry>[...weekly(SeedCategoryIds.travel, <int>[100]), _spent(100, SeedCategoryIds.travel, _oct(12))]), isEmpty);
    });

    test('fewer than 2 whole weeks is too early', () {
      expect(_evaluate(weekly(SeedCategoryIds.travel, <int>[100, 100]), asOf: _oct(17)), isEmpty);
    });

    test('a finished cycle counts its last day', () {
      // 4 Oct – 3 Nov has 31 days: four whole weeks once it is over.
      final List<Insight> insights = _evaluate(weekly(SeedCategoryIds.travel, <int>[100, 100, 100, 100]), asOf: _october.end);
      expect(insights, <Insight>[const SteadiestCategory(categoryId: SeedCategoryIds.travel)]);
    });
  });

  test('rules come in priority order: up, biggest, steadiest', () {
    final List<Insight> insights = _evaluate(
      <Entry>[
        _spent(100, SeedCategoryIds.travel, _oct(4)),
        _spent(100, SeedCategoryIds.travel, _oct(5)),
        _spent(100, SeedCategoryIds.travel, _oct(11)),
        _spent(100, SeedCategoryIds.travel, _oct(12)),
        _spent(10, SeedCategoryIds.food, _oct(5)),
        _spent(10, SeedCategoryIds.food, _oct(6)),
        _spent(5000, SeedCategoryIds.food, _oct(7)),
      ],
      previous: <Entry>[],
    );
    expect(insights.map((Insight i) => i.runtimeType), <Type>[CategoryUp, BiggestSpend, SteadiestCategory]);
  });

  test('InsightWindow compares by its fields', () {
    final Entry entry = _spent(100, SeedCategoryIds.food, _oct(5));
    expect(
      InsightWindow(cycle: _october, asOf: _today, entries: <Entry>[entry]).props,
      <Object?>[_october, _today, <Entry>[entry]],
    );
  });
}
