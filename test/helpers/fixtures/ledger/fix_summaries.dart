import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/domain/entities/cycle_inputs.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/ledger/domain/safe_to_spend.dart';

/// The cycle of the BR-4 worked example: 4 Oct to 3 Nov 2026.
const PayCycle workedPayCycle = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

/// A summary of the BR-4 worked example by default (I 45,000, B 1,200, S_prev 27,150, ₹420 today,
/// D 9, so H is 17,430), with any of its inputs changed, for the *Fix my number* tests.
CycleSummary fixSummary({
  int income = 45000,
  int bills = 1200,
  int spentBefore = 27150,
  int spentToday = 420,
  CalendarDate today = const CalendarDate(2026, 10, 26),
  PayCycle cycle = workedPayCycle,
}) =>
    SafeToSpend.compute(
      CycleInputs(
        cycle: cycle,
        today: today,
        income: Money.fromMajor(income),
        savingsDue: Money.zero,
        savedBefore: Money.zero,
        savedByRuleToday: Money.zero,
        savedExtraToday: Money.zero,
        billsDue: Money.fromMajor(bills),
        billsPostedToday: Money.zero,
        spentBefore: Money.fromMajor(spentBefore),
        spentToday: Money.fromMajor(spentToday),
        paceSpentBefore: Money.fromMajor(spentBefore),
        hasIncomeRule: true,
      ),
      earliestEntryDate: const CalendarDate(2026, 9, 4),
    );
