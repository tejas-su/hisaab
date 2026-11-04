import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_inputs.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_state.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_summary.dart';
import 'package:expense_tracker/ledger/domain/entities/put_in_preview.dart';
import 'package:expense_tracker/ledger/domain/entities/range_forecast.dart';
import 'package:expense_tracker/ledger/domain/entities/spend_preview.dart';
import 'package:expense_tracker/ledger/domain/entities/yesterday_saving.dart';
import 'package:expense_tracker/ledger/domain/safe_to_spend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Money _rupees(int rupees) => Money.fromMajor(rupees);

// The SPEC BR-4 / BR-7 worked example: payday on the 4th, today Mon 26 Oct 2026.
const PayCycle _cycle = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));
const CalendarDate _today = CalendarDate(2026, 10, 26);
const CalendarDate _earliest = CalendarDate(2026, 9, 4);

CycleInputs _inputs({
  CalendarDate today = _today,
  int income = 45000,
  int savingsDue = 0,
  int savedBefore = 0,
  int savedByRuleToday = 0,
  int savedExtraToday = 0,
  int billsDue = 1200,
  int spentBefore = 27150,
  int spentToday = 420,
  int paceSpentBefore = 18950,
  bool hasIncomeRule = true,
  int billsPostedToday = 0,
}) =>
    CycleInputs(
      cycle: _cycle,
      today: today,
      income: _rupees(income),
      savingsDue: _rupees(savingsDue),
      savedBefore: _rupees(savedBefore),
      savedByRuleToday: _rupees(savedByRuleToday),
      savedExtraToday: _rupees(savedExtraToday),
      billsDue: _rupees(billsDue),
      billsPostedToday: _rupees(billsPostedToday),
      spentBefore: _rupees(spentBefore),
      spentToday: _rupees(spentToday),
      paceSpentBefore: _rupees(paceSpentBefore),
      hasIncomeRule: hasIncomeRule,
    );

CycleSummary _compute(CycleInputs inputs) => SafeToSpend.compute(inputs, earliestEntryDate: _earliest);

// Sun 25 Oct, the day before the worked example: P = ₹16,650 over 10 days, so A = ₹1,665.
CycleInputs _yesterday({int spent = 0}) => _inputs(today: const CalendarDate(2026, 10, 25), spentToday: spent);

CycleSummary _computeWeek(CycleInputs inputs, {int spentThisWeek = 420}) =>
    SafeToSpend.compute(inputs, earliestEntryDate: _earliest, spentThisWeek: _rupees(spentThisWeek));

CycleSummary _computeAfter(CycleInputs yesterday) =>
    SafeToSpend.compute(_inputs(), earliestEntryDate: _earliest, yesterday: Option<CycleInputs>.of(yesterday));

void main() {
  group('SafeToSpend — savings (spec §3, D120)', () {
    test('an RD posted on the 10th leaves ₹1,294 for today (worked example 3)', () {
      final CycleSummary s = _compute(_inputs(savedBefore: 5000));
      expect(s.pool, _rupees(11650));
      expect(s.todayShare, _rupees(1294));
      expect(s.safeToday, _rupees(874));
    });

    test('the share is the same whether the RD is still to come, posted today or posted earlier', () {
      expect(_compute(_inputs(savingsDue: 5000)).todayShare, _rupees(1294));
      expect(_compute(_inputs(savedByRuleToday: 5000)).todayShare, _rupees(1294));
      expect(_compute(_inputs(savedBefore: 5000)).todayShare, _rupees(1294));
    });

    test('K is the three saving terms', () {
      expect(_inputs(savingsDue: 1000, savedBefore: 2000, savedByRuleToday: 3000).keepAside, _rupees(6000));
    });

    test('₹500 put in today keeps the share and thins tomorrow', () {
      final CycleSummary s = _compute(_inputs(savedBefore: 5000, savedExtraToday: 500));
      expect(s.todayShare, _rupees(1294));
      expect(s.safeToday, _rupees(874));
      expect(s.tomorrowShare, Option<Money>.of(_rupees(1341)));
      expect(s.remaining, _rupees(10730));
      expect(s.state, const OnTrack());
    });

    test('an extra thins the spare at payday', () {
      expect(_compute(_inputs(savedBefore: 5000)).forecast, LastsTillPayday(_rupees(4300)));
      expect(_compute(_inputs(savedBefore: 5000, savedExtraToday: 500)).forecast, LastsTillPayday(_rupees(3800)));
    });

    test('previewPutIn: ₹500 makes each day till payday ₹62 less', () {
      expect(SafeToSpend.previewPutIn(_compute(_inputs(savedBefore: 5000)), _rupees(500)), EachDayLess(_rupees(62)));
    });

    test('previewPutIn on the last day says payday is tomorrow (E-h)', () {
      final CycleSummary s = _compute(_inputs(today: const CalendarDate(2026, 11, 3), billsDue: 0));
      expect(SafeToSpend.previewPutIn(s, _rupees(500)), const PaydayTomorrow());
    });

    test('previewSpend after an extra uses what is left', () {
      final CycleSummary s = _compute(_inputs(savedBefore: 5000, savedExtraToday: 500));
      expect(
        SafeToSpend.previewSpend(s, _rupees(1000)),
        OverTodayShare(over: _rupees(126), tomorrow: Option<Money>.of(_rupees(1216))),
      );
    });

    test('money put in extra yesterday is not "under its share" (BR-8)', () {
      final CycleInputs yesterday = _inputs(today: const CalendarDate(2026, 10, 25), spentToday: 0, savedExtraToday: 1665);
      expect(_computeAfter(yesterday).savedYesterday, const Option<YesterdaySaving>.none());
    });

    test('an extra smaller than yesterday\'s underspend leaves the rest (BR-8)', () {
      final CycleInputs yesterday = _inputs(today: const CalendarDate(2026, 10, 25), spentToday: 0, savedExtraToday: 665);
      expect(_computeAfter(yesterday).savedYesterday.map((YesterdaySaving s) => s.saved), Option<Money>.of(_rupees(1000)));
    });

    test('a saving bigger than everything left is Over for the cycle (E-b)', () {
      final CycleSummary s = _compute(_inputs(savedByRuleToday: 20000));
      expect(s.todayShare, _rupees(0));
      expect(s.state, OverCycle(_rupees(3770)));
    });
  });

  group('SafeToSpend — bills posted today come out of the pool (BR-3, D119)', () {
    test('rent day: ₹15,000 posted today, nothing spent, hero shows ₹316 and is not over', () {
      final CycleSummary s = _compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 15000));
      expect(s.pool, _rupees(2850));
      expect(s.todayShare, _rupees(316));
      expect(s.state, isNot(isA<OverToday>()));
    });

    test('a changing bill entered today: ₹1,460 with ₹420 spent leaves ₹1,401', () {
      final CycleSummary s = _compute(_inputs(billsDue: 0, billsPostedToday: 1460));
      expect(s.todayShare, _rupees(1821));
      expect(s.todayShare - s.spentToday, _rupees(1401));
    });

    test('the share is the same whether the bill is still due or posted today', () {
      expect(
        _compute(_inputs(billsDue: 1200)).todayShare,
        _compute(_inputs(billsDue: 0, billsPostedToday: 1200)).todayShare,
      );
    });

    test('a bill posted today that overdraws the pool is Over for the cycle', () {
      final CycleSummary s = _compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 20000));
      expect(s.state, OverCycle(_rupees(2150)));
    });

    test('a bill today larger than the pool floors the share at ₹0', () {
      expect(_compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 20000)).todayShare, _rupees(0));
    });

    test('previewSpend on rent day fits within the new share', () {
      final CycleSummary s = _compute(_inputs(billsDue: 0, spentToday: 0, billsPostedToday: 15000));
      expect(SafeToSpend.previewSpend(s, _rupees(10)), FitsToday(_rupees(306)));
    });
  });

  group('SafeToSpend.compute — SPEC worked example', () {
    final CycleSummary summary = _compute(_inputs());

    test('BR-2: 9 days left, counting today', () {
      expect(summary.daysLeft, 9);
      expect(summary.payday, const CalendarDate(2026, 11, 4));
    });

    test('BR-3: pool P = I − K − B − S_prev = ₹16,650', () {
      expect(summary.pool, _rupees(16650));
    });

    test('BR-4: today\'s share ₹1,850, safe to spend ₹1,430', () {
      expect(summary.todayShare, _rupees(1850));
      expect(summary.safeToday, _rupees(1430));
    });

    test('BR-4: tomorrow\'s share floors (16,230 / 8 = ₹2,028)', () {
      expect(summary.tomorrowShare, Option<Money>.of(_rupees(2028)));
    });

    test('BR-5: on track', () {
      expect(summary.state, const OnTrack());
    });

    test('BR-7: lasts till payday with about ₹9,300 spare', () {
      expect(summary.forecast, LastsTillPayday(_rupees(9300)));
    });

    test('carries the earliest entry date through', () {
      expect(summary.earliestEntryDate, _earliest);
    });
  });

  group('SafeToSpend.compute — states (BR-5)', () {
    test('over today by ₹1,020 after ₹2,450 more; tomorrow ₹1,722', () {
      final CycleSummary summary = _compute(_inputs(spentToday: 2870));
      expect(summary.state, OverToday(_rupees(1020)));
      expect(summary.tomorrowShare, Option<Money>.of(_rupees(1722)));
      expect(summary.todayShare, _rupees(1850), reason: 'A is fixed for the day');
    });

    test('over for the cycle when today\'s spend passes the pool', () {
      final CycleSummary summary = _compute(_inputs(spentToday: 17000));
      expect(summary.state, OverCycle(_rupees(350)));
    });

    test('slow down when under a quarter of today\'s share is left', () {
      expect(_compute(_inputs(spentToday: 1400)).state, const SlowDown());
    });

    test('exactly a quarter left is still on track', () {
      // A = ₹1,800 with P = ₹16,200; a quarter is ₹450.
      expect(_compute(_inputs(billsDue: 1650, spentToday: 1350)).state, const OnTrack());
    });

    test('slow down when the pace runs out before payday (BR-7)', () {
      final CycleSummary summary = _compute(_inputs(billsDue: 0, spentBefore: 40000, spentToday: 0, paceSpentBefore: 40000));
      expect(summary.todayShare, _rupees(555));
      expect(summary.forecast, const RunsOut(CalendarDate(2026, 10, 29)));
      expect(summary.state, const SlowDown());
    });

    test('no income: no Got entry and no salary rule (E10)', () {
      expect(_compute(_inputs(income: 0, hasIncomeRule: false)).state, const NoIncome());
    });

    test('a salary rule that hasn\'t posted yet is not "no income"', () {
      expect(_compute(_inputs(income: 0)).state, isNot(const NoIncome()));
    });

    test('E4: a pool of ₹0 gives A = 0 and slow down, never a negative hero', () {
      final CycleSummary summary = _compute(_inputs(billsDue: 0, spentBefore: 45000, spentToday: 0, paceSpentBefore: 0));
      expect(summary.todayShare, Money.zero);
      expect(summary.state, const SlowDown());
    });

    test('E5: a bill bigger than the money left makes the cycle over', () {
      final CycleSummary summary = _compute(_inputs(billsDue: 20000));
      expect(summary.todayShare, Money.zero);
      expect(summary.state, OverCycle(_rupees(2570)));
    });

    test('money saved earlier this cycle is never spendable (D120)', () {
      expect(_compute(_inputs(savedBefore: 1650)).pool, _rupees(15000));
    });
  });

  group('SafeToSpend.compute — edge days', () {
    test('E2: on the last day there is no tomorrow and the money lasts', () {
      final CycleSummary summary = _compute(
        _inputs(today: const CalendarDate(2026, 11, 3), billsDue: 0, spentBefore: 44000, spentToday: 0, paceSpentBefore: 30000),
      );
      expect(summary.daysLeft, 1);
      expect(summary.todayShare, _rupees(1000));
      expect(summary.tomorrowShare, const Option<Money>.none());
      expect(summary.forecast, LastsTillPayday(_rupees(1000)));
    });

    test('BR-7: fewer than 3 days of history is too early to forecast', () {
      final CycleSummary summary = _compute(_inputs(today: const CalendarDate(2026, 10, 6)));
      expect(summary.forecast, const TooEarlyToForecast());
    });

    test('BR-7: exactly 3 days of history forecasts', () {
      final CycleSummary summary = _compute(_inputs(today: const CalendarDate(2026, 10, 7), spentBefore: 900, paceSpentBefore: 900));
      expect(summary.forecast, isA<LastsTillPayday>());
    });

    test('BR-7: no typed spending yet means the money lasts', () {
      final CycleSummary summary = _compute(_inputs(spentBefore: 8200, paceSpentBefore: 0, spentToday: 0));
      expect(summary.forecast, LastsTillPayday(_rupees(35600)));
    });

    test('BR-7: no typed spending and a negative pool runs out today', () {
      final CycleSummary summary = _compute(_inputs(billsDue: 50000, paceSpentBefore: 0));
      expect(summary.forecast, const RunsOut(_today));
    });

    test('BR-7: spare rounds to the nearest ₹100', () {
      // remaining 1,250 with no pace → about ₹1,300.
      final CycleSummary summary =
          _compute(_inputs(income: 1250, billsDue: 0, spentBefore: 0, spentToday: 0, paceSpentBefore: 0));
      expect(summary.forecast, LastsTillPayday(_rupees(1300)));
    });
  });

  group('SafeToSpend.previewSpend (FR-AD-3)', () {
    final CycleSummary summary = _compute(_inputs());

    test('an amount within today\'s share shows what is left', () {
      expect(SafeToSpend.previewSpend(summary, _rupees(1000)), FitsToday(_rupees(430)));
    });

    test('spending exactly the rest of today leaves ₹0', () {
      expect(SafeToSpend.previewSpend(summary, _rupees(1430)), FitsToday(Money.zero));
    });

    test('₹2,450 goes ₹1,020 over and leaves ₹1,722 a day', () {
      expect(
        SafeToSpend.previewSpend(summary, _rupees(2450)),
        OverTodayShare(over: _rupees(1020), tomorrow: Option<Money>.of(_rupees(1722))),
      );
    });

    test('on the last day an overspend has no tomorrow', () {
      final CycleSummary lastDay = _compute(_inputs(today: const CalendarDate(2026, 11, 3)));
      expect(
        SafeToSpend.previewSpend(lastDay, lastDay.todayShare + _rupees(1)),
        isA<OverTodayShare>().having((OverTodayShare p) => p.tomorrow, 'tomorrow', const Option<Money>.none()),
      );
    });
  });

  group('CycleSummary.safeThisWeek (FR-HO-2)', () {
    test('worked example: 7 × ₹1,850 − ₹420 spent since Monday = ₹12,530', () {
      expect(_computeWeek(_inputs()).safeThisWeek, _rupees(12530));
    });

    test('fewer than 7 days to payday counts only the days left', () {
      // Fri 30 Oct: D = 5, A = 16,650 / 5 = ₹3,330.
      final CycleSummary summary = _computeWeek(_inputs(today: const CalendarDate(2026, 10, 30)), spentThisWeek: 1000);
      expect(summary.safeThisWeek, _rupees(5 * 3330 - 1000));
    });

    test('on the last day only today\'s share counts', () {
      final CycleSummary summary = _computeWeek(_inputs(today: const CalendarDate(2026, 11, 3)), spentThisWeek: 0);
      expect(summary.safeThisWeek, summary.todayShare);
    });

    test('goes below ₹0 when the week\'s spending passes its shares', () {
      expect(_computeWeek(_inputs(), spentThisWeek: 13000).safeThisWeek, _rupees(-50));
    });

    test('A = 0 leaves only what was spent, as a negative', () {
      final CycleSummary summary = _computeWeek(_inputs(billsDue: 20000));
      expect(summary.safeThisWeek, _rupees(-420));
    });
  });

  group('SafeToSpend.compute — saved yesterday (BR-8)', () {
    test('no yesterday given means no note', () {
      expect(_compute(_inputs()).savedYesterday, const Option<YesterdaySaving>.none());
    });

    test('nothing spent yesterday saves the whole ₹1,665 share; each of 9 days gets ₹185 more', () {
      expect(
        _computeAfter(_yesterday()).savedYesterday,
        Option<YesterdaySaving>.of(YesterdaySaving(saved: _rupees(1665), eachDayMore: _rupees(185))),
      );
    });

    test('spending ₹1,365 saves ₹300; the ₹33.33 a day floors to ₹33', () {
      expect(
        _computeAfter(_yesterday(spent: 1365)).savedYesterday,
        Option<YesterdaySaving>.of(YesterdaySaving(saved: _rupees(300), eachDayMore: _rupees(33))),
      );
    });

    test('saving less than one rupee a day still counts, with ₹0 more each day', () {
      expect(
        _computeAfter(_yesterday(spent: 1660)).savedYesterday,
        Option<YesterdaySaving>.of(YesterdaySaving(saved: _rupees(5), eachDayMore: Money.zero)),
      );
    });

    test('spending exactly yesterday\'s share saves nothing', () {
      expect(_computeAfter(_yesterday(spent: 1665)).savedYesterday, const Option<YesterdaySaving>.none());
    });

    test('overspending yesterday saves nothing', () {
      expect(_computeAfter(_yesterday(spent: 2000)).savedYesterday, const Option<YesterdaySaving>.none());
    });

    test('a share of ₹0 yesterday saves nothing', () {
      final CycleInputs broke = _inputs(today: const CalendarDate(2026, 10, 25), billsDue: 20000, spentToday: 0);
      expect(_computeAfter(broke).savedYesterday, const Option<YesterdaySaving>.none());
    });
  });
}
