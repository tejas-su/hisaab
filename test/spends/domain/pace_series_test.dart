import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/domain/entities/pace_series.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _cycle = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

PaceSeries _series(
  Iterable<Entry> entries, {
  CalendarDate asOf = WorkedExample.today,
  int budget = 45000,
  List<DatedAmount> billsDue = const <DatedAmount>[],
}) =>
    PaceSeries.of(entries, cycle: _cycle, asOf: asOf, budget: Money.fromMajor(budget), billsDue: billsDue)
        .getOrElse(() => fail('no series'));

Entry _spent(int rupees, CalendarDate date, {EntryKind kind = EntryKind.spent, int? recurringId}) => Entry(
      id: date.day,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: 1,
      date: date,
      createdAt: DateTime(2026, 10, 1),
      recurringId: recurringId,
    );

const CalendarDate _rentDay = CalendarDate(2026, 10, 5);

void main() {
  group('PaceSeries.of (FR-SP-3)', () {
    test('worked example: ₹27,570 spent by 26 Oct, below the ₹35,503 steady pace', () {
      final PaceSeries series = _series(WorkedExample.entries);
      expect(series.cycleDays, 31);
      expect(series.spentByDay, hasLength(23));
      expect(series.spentSoFar, Money.fromMajor(27570));
      // Rent ₹8,200 on its day, plus 23/31 of the other ₹36,800 (D129).
      expect(series.steadyThrough(22), Money.fromMajor(35503));
      expect(series.verdict, PaceVerdict.belowPace);
    });

    test('totals run day by day: rent on 5 Oct shows from day 1 on', () {
      final PaceSeries series = _series(WorkedExample.entries);
      expect(series.spentByDay[0], Money.zero);
      expect(series.spentByDay[1], Money.fromMajor(8200));
      expect(series.spentByDay[16], Money.fromMajor(27150));
    });

    test('spending past the steady line is above pace', () {
      expect(_series(<Entry>[_spent(5000, const CalendarDate(2026, 10, 4))], asOf: const CalendarDate(2026, 10, 5)).verdict,
          PaceVerdict.abovePace);
    });

    test('exactly on the steady line is below pace', () {
      // ₹31,000 over 31 days: ₹1,000 a day; ₹2,000 by the end of day 2.
      expect(
        _series(<Entry>[_spent(2000, const CalendarDate(2026, 10, 4))], asOf: const CalendarDate(2026, 10, 5), budget: 31000).verdict,
        PaceVerdict.belowPace,
      );
    });

    test('a past cycle runs to its last day and ends on the budget', () {
      final PaceSeries series = _series(const <Entry>[], asOf: _cycle.end);
      expect(series.spentByDay, hasLength(31));
      expect(series.steadyThrough(30), Money.fromMajor(45000));
    });

    test('Got entries and entries outside the window are left out', () {
      final PaceSeries series = _series(<Entry>[
        _spent(45000, const CalendarDate(2026, 10, 4), kind: EntryKind.got),
        _spent(100, const CalendarDate(2026, 10, 3)),
        _spent(100, const CalendarDate(2026, 10, 27)),
      ]);
      expect(series.spentSoFar, Money.zero);
    });

    // Regression: the steady line was a straight ramp, so rent on day 2 read "Spending faster"
    // for most of the month (₹8,200 against ₹2,903) though nothing else was spent.
    test('a bill posted on its day steps the steady line up, so rent alone is spending slower', () {
      final PaceSeries series = _series(<Entry>[_spent(8200, _rentDay, recurringId: 2)], asOf: _rentDay);
      expect(series.steadyThrough(0), Money.fromMajor(1187));
      expect(series.steadyThrough(1), Money.fromMajor(10574));
      expect(series.verdict, PaceVerdict.belowPace);
    });

    test('the same amount typed by hand is spending, not a bill, so it is faster', () {
      final PaceSeries series = _series(<Entry>[_spent(8200, _rentDay)], asOf: _rentDay);
      expect(series.steadyThrough(1), Money.fromMajor(2903));
      expect(series.verdict, PaceVerdict.abovePace);
    });

    test('a bill still to come steps the line on its day and the line still ends on the budget', () {
      final PaceSeries series = _series(
        <Entry>[_spent(8200, _rentDay, recurringId: 2)],
        billsDue: <DatedAmount>[(date: const CalendarDate(2026, 10, 29), amount: Money.fromMajor(1200))],
      );
      // 29 Oct is day 25: ₹35,600 × 25/31 = 28,709, then × 26/31 = 29,858.
      expect(series.steadyThrough(24), Money.fromMajor(8200 + 28709));
      expect(series.steadyThrough(25), Money.fromMajor(8200 + 1200 + 29858));
      expect(series.steadyThrough(30), Money.fromMajor(45000));
    });

    test('a bill due outside the cycle is left out', () {
      final PaceSeries series = _series(
        const <Entry>[],
        billsDue: <DatedAmount>[(date: const CalendarDate(2026, 11, 4), amount: Money.fromMajor(1200))],
      );
      expect(series.steadyThrough(30), Money.fromMajor(45000));
      expect(series.steadyThrough(0), Money.fromMajor(1451));
    });

    test('bills past the budget: the line is the bills alone and the top reaches them', () {
      final PaceSeries series = _series(<Entry>[_spent(8200, _rentDay, recurringId: 2)], asOf: _cycle.end, budget: 5000);
      expect(series.steadyThrough(0), Money.zero);
      expect(series.steadyThrough(30), Money.fromMajor(8200));
      expect(series.top, Money.fromMajor(8200));
    });

    test('no money to spend gives no chart', () {
      expect(PaceSeries.of(const <Entry>[], cycle: _cycle, asOf: WorkedExample.today, budget: Money.zero), const Option<PaceSeries>.none());
      expect(
        PaceSeries.of(const <Entry>[], cycle: _cycle, asOf: WorkedExample.today, budget: Money.fromMajor(-10)),
        const Option<PaceSeries>.none(),
      );
    });
  });

  group('PaceSeries axis (FR-SP-3)', () {
    final List<(int, int, List<int>)> axes = <(int, int, List<int>)>[
      (45000, 20000, <int>[0, 20000, 40000]),
      (30000, 10000, <int>[0, 10000, 20000, 30000]),
      (100000, 50000, <int>[0, 50000, 100000]),
      (1, 1, <int>[0, 1]),
      (7, 5, <int>[0, 5]),
    ];
    for (final (int budget, int step, List<int> labels) in axes) {
      test('₹$budget: step ₹$step, labels $labels', () {
        final PaceSeries series = _series(const <Entry>[], budget: budget);
        expect(series.axisStep, Money.fromMajor(step));
        expect(series.axisLabels, labels.map(Money.fromMajor).toList());
      });
    }

    test('spending past the budget raises the top and adds a label', () {
      final PaceSeries series = _series(<Entry>[_spent(50000, const CalendarDate(2026, 10, 10))]);
      expect(series.top, Money.fromMajor(50000));
      expect(series.axisLabels.last, Money.fromMajor(40000));
      final PaceSeries far = _series(<Entry>[_spent(61000, const CalendarDate(2026, 10, 10))]);
      expect(far.axisLabels.last, Money.fromMajor(60000));
    });

    // Regression: the step came from the budget alone, so a large overspend drew one label per
    // step all the way up (₹1 budget, ₹1L spent → 1,00,001 labels), which hung the app.
    final List<(int, int, int, List<int>)> overspends = <(int, int, int, List<int>)>[
      (3000, 500000, 200000, <int>[0, 200000, 400000]),
      (1, 100000, 50000, <int>[0, 50000, 100000]),
      (45000, 99999999, 20000000, <int>[0, 20000000, 40000000, 60000000, 80000000]),
      (45000, 81000, 20000, <int>[0, 20000, 40000, 60000, 80000]),
      (45000, 101000, 50000, <int>[0, 50000, 100000]),
    ];
    for (final (int budget, int spent, int step, List<int> labels) in overspends) {
      test('₹$budget budget, ₹$spent spent: at most 4 steps, every ₹$step', () {
        final PaceSeries series = _series(<Entry>[_spent(spent, const CalendarDate(2026, 10, 10))], budget: budget);
        expect(series.axisStep, Money.fromMajor(step));
        expect(series.axisLabels, labels.map(Money.fromMajor).toList());
      });
    }
  });
}
