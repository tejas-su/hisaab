import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';

/// The totals that SPEC BR-3 to BR-7 need, gathered from the ledger for one day of one cycle.
final class CycleInputs extends Equatable {
  const CycleInputs({
    required this.cycle,
    required this.today,
    required this.income,
    required this.keepAside,
    required this.billsDue,
    required this.spentBefore,
    required this.spentToday,
    required this.paceSpentBefore,
    required this.hasIncomeRule,
  });

  final PayCycle cycle;
  final CalendarDate today;

  /// `I`: every *Got* entry dated in the cycle.
  final Money income;

  /// `K`: money kept aside this cycle.
  final Money keepAside;

  /// `B`: recurring *Spent* occurrences due after today within the cycle, not yet posted.
  final Money billsDue;

  /// `S_prev`: *Spent* entries from the cycle start to yesterday.
  final Money spentBefore;

  /// `S_today`: *Spent* entries dated today.
  final Money spentToday;

  /// `V_prev`: the part of [spentBefore] that no recurring rule posted (BR-7 pace).
  final Money paceSpentBefore;

  /// Whether a salary rule exists, even if it hasn't posted yet (BR-5 #1).
  final bool hasIncomeRule;

  @override
  List<Object?> get props =>
      <Object?>[cycle, today, income, keepAside, billsDue, spentBefore, spentToday, paceSpentBefore, hasIncomeRule];
}
