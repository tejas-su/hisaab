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
    required this.savingsDue,
    required this.savedBefore,
    required this.savedByRuleToday,
    required this.savedExtraToday,
    required this.billsDue,
    required this.billsPostedToday,
    required this.spentBefore,
    required this.spentToday,
    required this.paceSpentBefore,
    required this.hasIncomeRule,
  });

  final PayCycle cycle;
  final CalendarDate today;

  /// `I`: every *Got* entry dated in the cycle.
  final Money income;

  /// `R`: saving occurrences due after today within the cycle, not yet posted (D120).
  final Money savingsDue;

  /// *Saved* entries from the cycle start to yesterday, by a rule or put in extra (D120).
  final Money savedBefore;

  /// *Saved* entries dated today that a saving rule posted (D120).
  final Money savedByRuleToday;

  /// *Saved* entries dated today with no rule (*Put in extra*). They leave today's share fixed
  /// and thin the days after it, like an overspend (spec §3, D120).
  final Money savedExtraToday;

  /// `K`, computed: everything set aside for savings this cycle up to the start of today
  /// (spec §3, D120). A saving is reserved before its day and comes out of the pool on it.
  Money get keepAside => savingsDue + savedBefore + savedByRuleToday;

  /// `B`: recurring *Spent* occurrences due after today within the cycle, not yet posted.
  final Money billsDue;

  /// `R_t`: *Spent* entries dated today that a recurring rule posted (bills). They come out of
  /// the pool, not today's share (BR-3, DECISIONS D119).
  final Money billsPostedToday;

  /// `S_prev`: *Spent* entries from the cycle start to yesterday.
  final Money spentBefore;

  /// `S_today`: *Spent* entries dated today that no recurring rule posted.
  final Money spentToday;

  /// `V_prev`: the part of [spentBefore] that no recurring rule posted (BR-7 pace).
  final Money paceSpentBefore;

  /// Whether a salary rule exists, even if it hasn't posted yet (BR-5 #1).
  final bool hasIncomeRule;

  @override
  List<Object?> get props =>
      <Object?>[cycle, today, income, savingsDue, savedBefore, savedByRuleToday, savedExtraToday, billsDue, billsPostedToday, spentBefore, spentToday, paceSpentBefore, hasIncomeRule];
}
