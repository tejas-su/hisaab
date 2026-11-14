import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/domain/entities/cycle_inputs.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/fix_preview.dart';
import 'package:hisaab/ledger/domain/fix_my_number.dart';
import 'package:hisaab/ledger/domain/safe_to_spend.dart';

const PayCycle _cycle = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

Money _r(int rupees) => Money.fromMajor(rupees);

/// The BR-4 worked example by default: I 45,000, B 1,200, S_prev 27,150, ₹420 today, D 9, H 17,430.
CycleSummary _summary({
  int income = 45000,
  int keepSavingsDue = 0,
  int saved = 0,
  int bills = 1200,
  int spentBefore = 27150,
  int spentToday = 420,
  int extraPaise = 0,
  CalendarDate today = const CalendarDate(2026, 10, 26),
  PayCycle cycle = _cycle,
}) =>
    SafeToSpend.compute(
      CycleInputs(
        cycle: cycle,
        today: today,
        income: _r(income),
        savingsDue: _r(keepSavingsDue),
        savedBefore: _r(saved),
        savedByRuleToday: Money.zero,
        savedExtraToday: Money.zero,
        billsDue: _r(bills),
        billsPostedToday: Money.zero,
        spentBefore: _r(spentBefore) + Money(extraPaise),
        spentToday: _r(spentToday),
        paceSpentBefore: _r(spentBefore),
        hasIncomeRule: true,
      ),
      earliestEntryDate: const CalendarDate(2026, 9, 4),
    );

FixPreview _preview(CycleSummary summary, int typed) => FixMyNumber.preview(summary, Option<int>.of(typed));

/// BR-18, its table and its worked examples.
void main() {
  group('FixMyNumber.held (BR-18)', () {
    test('H is remaining plus B plus R, unclamped', () {
      expect(FixMyNumber.held(_summary()), _r(17430));
      expect(FixMyNumber.held(_summary(spentBefore: 46000, spentToday: 0, bills: 0)), _r(-1000));
    });

    test('a yearly saving: K 1,000 saved, H is 16,430 and the same example holds', () {
      final CycleSummary withSaving = _summary(saved: 1000);

      expect(FixMyNumber.held(withSaving), _r(16430));
    });
  });

  group('golden cases (BR-18 worked example)', () {
    test('case 1: ₹13,230 typed, lower by 4,200, each day about 467 less, hero 963', () {
      final CycleSummary summary = _summary();

      final FixPreview preview = _preview(summary, 13230);

      expect(preview, isA<FixLower>());
      final FixLower lower = preview as FixLower;
      expect(lower.held, _r(17430));
      expect(lower.gap, _r(4200));
      expect(lower.shareAfter, _r(1383));
      expect(lower.shareAfter - summary.spentToday, _r(963));
      expect(lower.perDay, _r(467));
      expect(lower.lastDay, isFalse);
      expect(FixMyNumber.post(summary, 13230), Option<FixPost>.of(FixPost(kind: EntryKind.spent, amount: _r(4200))));
    });

    test('case 2: ₹18,430 typed, higher by 1,000, each day about 111 more, hero 1,541', () {
      final CycleSummary summary = _summary();

      final FixPreview preview = _preview(summary, 18430);

      final FixHigher higher = preview as FixHigher;
      expect(higher.gap, _r(1000));
      expect(higher.shareAfter, _r(1961));
      expect(higher.shareAfter - summary.spentToday, _r(1541));
      expect(higher.perDay, _r(111));
      expect(FixMyNumber.post(summary, 18430), Option<FixPost>.of(FixPost(kind: EntryKind.got, amount: _r(1000))));
    });

    test('case 3: ₹47,430 typed, a ₹30,000 gap over I ÷ 10 is large; A 5,183, hero 4,763', () {
      final CycleSummary summary = _summary();

      final FixLarge large = _preview(summary, 47430) as FixLarge;

      expect(large.gap, _r(30000));
      expect(large.shareAfter, _r(5183));
      expect(large.shareAfter - summary.spentToday, _r(4763));
      expect(FixMyNumber.post(summary, 47430), Option<FixPost>.of(FixPost(kind: EntryKind.got, amount: _r(30000))));
    });

    test('case 3b: after No the user types 17,430 and it matches', () {
      expect(_preview(_summary(), 17430), isA<FixEqual>());
    });

    test('close: 17,400 is within ₹50 of 17,430 (E73)', () {
      final FixPreview preview = _preview(_summary(), 17400);

      expect(preview, isA<FixClose>());
      expect(FixMyNumber.post(_summary(), 17400), const Option<FixPost>.none());
    });

    test('short: ₹1,000 typed is ₹200 short of the 1,200 still due; A 24, hero 0', () {
      final CycleSummary summary = _summary();

      final FixShort short = _preview(summary, 1000) as FixShort;

      expect(short.gap, _r(16430));
      expect(short.short, _r(200));
      expect(short.shareAfter, _r(24));
      expect(short.shareAfter < summary.spentToday, isTrue);
    });

    test('mid-cycle install: 9,000 typed against H 45,000 posts a Spent 36,000, hero 866', () {
      final CycleSummary summary = _summary(spentBefore: 0, spentToday: 0);

      final FixLower lower = _preview(summary, 9000) as FixLower;

      expect(FixMyNumber.held(summary), _r(45000));
      expect(lower.gap, _r(36000));
      expect(lower.shareAfter, _r(866));
      expect(lower.shareAfter - summary.spentToday, _r(866));
    });

    test('last day: D 1, 930 typed posts Spent 500 and says today takes all of it', () {
      final CycleSummary summary = _summary(spentBefore: 43150, bills: 0, today: _cycle.end);

      final FixLower lower = _preview(summary, 930) as FixLower;

      expect(summary.daysLeft, 1);
      expect(summary.safeToday, _r(1430));
      expect(lower.gap, _r(500));
      expect(lower.shareAfter, _r(1350));
      expect(lower.shareAfter - summary.spentToday, _r(930));
      expect(lower.lastDay, isTrue);
    });

    test('last day higher says today gets all of it', () {
      final CycleSummary summary = _summary(spentBefore: 43150, bills: 0, today: _cycle.end);

      expect((_preview(summary, 2000) as FixHigher).lastDay, isTrue);
    });

    test('with a yearly saving (K 1,000): 12,230 typed, Spent 4,200, A 1,272, hero 852, about 466 less', () {
      final CycleSummary summary = _summary(saved: 1000);

      final FixLower lower = _preview(summary, 12230) as FixLower;

      expect(lower.gap, _r(4200));
      expect(lower.shareAfter, _r(1272));
      expect(lower.shareAfter - summary.spentToday, _r(852));
      expect(lower.perDay, _r(466));
    });

    test('H = -300, T = 2,000: Got 2,300 under 4,500, no guard, line one says short', () {
      final CycleSummary summary = _summary(spentBefore: 45300, spentToday: 0, bills: 0);

      final FixHigher higher = _preview(summary, 2000) as FixHigher;

      expect(higher.held, _r(-300));
      expect(higher.heldLine, HeldLine.short);
      expect(higher.gap, _r(2300));
    });

    test('H = 0 says nothing was left', () {
      final CycleSummary summary = _summary(spentBefore: 45000, spentToday: 0, bills: 0);

      final FixPreview preview = _preview(summary, 1000);

      expect(preview.held, Money.zero);
      expect(preview.heldLine, HeldLine.nothing);
      expect(preview, isA<FixHigher>());
    });

    test('over today: 2,430 typed is a lower of 15,000 with today ₹237 over its share', () {
      final FixOverToday over = _preview(_summary(), 2430) as FixOverToday;

      expect(over.gap, _r(15000));
      expect(over.shareAfter, _r(183));
      expect(over.over, _r(237));
    });
  });

  group('states and boundaries', () {
    test('empty is FixEmpty and carries H; typed 0 is a valid state (E74)', () {
      final CycleSummary summary = _summary();

      expect(FixMyNumber.preview(summary, const Option<int>.none()), FixEmpty(held: _r(17430)));
      expect(_preview(summary, 0), isA<FixShort>());
    });

    test('T = H is equal (E72) and posts nothing', () {
      final CycleSummary summary = _summary();

      expect(_preview(summary, 17430), isA<FixEqual>());
      expect(FixMyNumber.post(summary, 17430), const Option<FixPost>.none());
    });

    test('close at a gap of exactly ₹50 with T a multiple of 100, not close at ₹50.01', () {
      final CycleSummary atFifty = _summary(spentToday: 400); // H 17,450
      final CycleSummary overFifty = _summary(spentToday: 399); // H 17,451

      expect(_preview(atFifty, 17400), isA<FixClose>());
      expect(_preview(overFifty, 17400), isA<FixLower>());
    });

    test('close needs T to be a multiple of 100: T = 17,420 (gap 10) is lower of 10, not close', () {
      final FixLower lower = _preview(_summary(), 17420) as FixLower;

      expect(lower.gap, _r(10));
    });

    test('T = H minus one rupee is a lower of ₹1', () {
      expect((_preview(_summary(), 17429) as FixLower).gap, _r(1));
      expect(FixMyNumber.post(_summary(), 17429), Option<FixPost>.of(FixPost(kind: EntryKind.spent, amount: _r(1))));
    });

    test('a gap under ₹1 is equal and a gap of ₹4,200.50 posts ₹4,200 (weekly pay can leave paise)', () {
      final CycleSummary paise = SafeToSpend.compute(
        CycleInputs(
          cycle: _cycle,
          today: const CalendarDate(2026, 10, 26),
          income: _r(45000),
          savingsDue: Money.zero,
          savedBefore: Money.zero,
          savedByRuleToday: Money.zero,
          savedExtraToday: Money.zero,
          billsDue: _r(1200),
          billsPostedToday: Money.zero,
          spentBefore: Money(2715050),
          spentToday: _r(420),
          paceSpentBefore: Money.zero,
          hasIncomeRule: true,
        ),
        earliestEntryDate: const CalendarDate(2026, 9, 4),
      );

      expect(FixMyNumber.held(paise), Money(1742950));
      expect((_preview(paise, 13230) as FixLower).gap, _r(4199));
      expect(_preview(paise, 17429), isA<FixEqual>());
    });

    test('higher equal to I ÷ 10 is higher; one paisa more is large', () {
      final CycleSummary atGuard = _summary(); // H 17,430; I ÷ 10 = 4,500
      final CycleSummary paisaOver = _summary(extraPaise: 1);

      expect(_preview(atGuard, 21930), isA<FixHigher>());
      expect(_preview(paisaOver, 21930), isA<FixLarge>());
    });

    test('a huge lower gap is lower, never large: no guard on lower (D167, E79)', () {
      expect(_preview(_summary(), 1500), isA<FixOverToday>());
      expect(_preview(_summary(spentBefore: 0, spentToday: 0, bills: 0), 1500), isA<FixLower>());
    });

    test('short beats over today beats lower', () {
      final CycleSummary summary = _summary();

      expect(_preview(summary, 1000), isA<FixShort>());
      expect(_preview(summary, 2430), isA<FixOverToday>());
      expect(_preview(summary, 13230), isA<FixLower>());
    });

    test('n_day = 0 says each day stays about the same', () {
      final CycleSummary summary = _summary(spentBefore: 27150, spentToday: 0, bills: 0); // H 17,850 and A 1,983

      final FixLower lower = _preview(summary, 17849) as FixLower;

      expect(lower.perDay, Money.zero);
    });

    test('a weekly cycle and a bridge cycle use the current cycle I', () {
      const PayCycle weekly = PayCycle(start: CalendarDate(2026, 10, 19), end: CalendarDate(2026, 10, 25));
      final CycleSummary summary = _summary(income: 7000, bills: 0, spentBefore: 3000, spentToday: 0, today: const CalendarDate(2026, 10, 22), cycle: weekly);

      expect(FixMyNumber.held(summary), _r(4000));
      expect(_preview(summary, 4700), isA<FixHigher>());
      expect(_preview(summary, 4701), isA<FixLarge>());
    });

    test('a Got fix on day 1 with a large buffer is large (E79)', () {
      final CycleSummary dayOne = _summary(spentBefore: 0, spentToday: 0, bills: 0, today: _cycle.start);

      expect(_preview(dayOne, 60000), isA<FixLarge>());
    });

    test('two fixes: the second compares with the ledger as it is and matches (E83)', () {
      final CycleSummary afterFirst = _summary(spentBefore: 27150 + 4200);

      expect(_preview(afterFirst, 13230), isA<FixEqual>());
    });
  });
}
