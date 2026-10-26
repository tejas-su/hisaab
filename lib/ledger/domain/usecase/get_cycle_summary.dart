import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/budget_settings.dart';
import '../entities/cycle_inputs.dart';
import '../entities/cycle_summary.dart';
import '../entities/entry.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../pay_rule_schedule.dart';
import '../recurring_schedule.dart';
import '../repository/budget_settings_repository.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import '../safe_to_spend.dart';

/// Loads the current cycle's data and works out today's [CycleSummary] (SPEC BR-1 to BR-7).
final class GetCycleSummary implements UseCase<CycleSummary, NoParams> {
  const GetCycleSummary({
    required this._ledger,
    required this._recurring,
    required this._settings,
    required this._periods,
    required this._clock,
  });

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
  final BudgetSettingsRepository _settings;
  final PeriodCalculator _periods;
  final Clock _clock;

  /// Returns [Right] with today's summary (state [NoIncome] when there is nothing to share), or
  /// [Left] with `DatabaseFailure` or `InvalidDataFailure` when a read fails.
  @override
  TaskEither<Failure, CycleSummary> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return _settings.read().flatMap(
          (BudgetSettings settings) => _recurring.activeRules().flatMap(
                (List<RecurringRule> rules) => _summarise(today, settings, rules),
              ),
        );
  }

  TaskEither<Failure, CycleSummary> _summarise(CalendarDate today, BudgetSettings settings, List<RecurringRule> rules) {
    final Option<RecurringRule> income = Option<RecurringRule>.fromNullable(
      rules.where((RecurringRule rule) => rule.isIncomeSource).firstOrNull,
    );
    final PayRule payRule = PayRuleSchedule.payRuleOf(income);
    final PayCycle cycle = _periods.cycleFor(today: today, rule: payRule, monthStart: settings.monthStart);
    final PayCycle previous =
        _periods.cycleFor(today: cycle.start.addDays(-1), rule: payRule, monthStart: settings.monthStart);
    final Money billsDue = _sum(
      rules.where((RecurringRule r) => r.kind == EntryKind.spent).expand((RecurringRule r) => _billsAfter(r, today, cycle)),
    );
    final _DayTotals day = _DayTotals(cycle: cycle, settings: settings, hasIncomeRule: income.isSome());
    return _ledger.firstLoggedOn().flatMap(
          (Option<CalendarDate> firstLogged) => _ledger.entriesBetween(cycle.start, cycle.end).map(
                (List<Entry> entries) => SafeToSpend.compute(
                  day.inputs(today, entries, billsDue: billsDue),
                  earliestEntryDate: previous.start,
                  spentThisWeek: _spentThisWeek(entries, today),
                  yesterday: _trackedYesterday(firstLogged, today).flatMap(
                    (CalendarDate _) => _yesterday(day, today, entries, billsDue: billsDue),
                  ),
                ),
              ),
        );
  }

  // why: an app installed today back-posts salary to the cycle start, so yesterday's "saving"
  // would be money nobody tracked. Only a day the app was already in use earns the note.
  static Option<CalendarDate> _trackedYesterday(Option<CalendarDate> firstLogged, CalendarDate today) =>
      firstLogged.filter((CalendarDate day) => day.isBefore(today)).map((CalendarDate _) => today.addDays(-1));

  // why: entries are loaded from the cycle start, so a week begun last cycle counts this cycle's days only.
  static Money _spentThisWeek(List<Entry> entries, CalendarDate today) {
    final CalendarDate monday = today.addDays(DateTime.monday - today.weekday);
    return _sum(
      entries
          .where((Entry e) => e.kind == EntryKind.spent && !e.date.isBefore(monday) && !e.date.isAfter(today))
          .map((Entry e) => e.amount),
    );
  }

  // why: rebuilds the day as it stood yesterday. Bills the engine posted today were still due
  // then, and money that came in today hadn't arrived yet (BR-8).
  static Option<CycleInputs> _yesterday(_DayTotals day, CalendarDate today, List<Entry> entries, {required Money billsDue}) {
    final CalendarDate yesterday = today.addDays(-1);
    if (!day.cycle.contains(yesterday)) {
      return const Option<CycleInputs>.none();
    }
    final Money postedToday = _sum(
      entries.where((Entry e) => e.date == today && e.kind == EntryKind.spent && e.recurringId != null).map((Entry e) => e.amount),
    );
    final List<Entry> before = entries.where((Entry e) => !e.date.isAfter(yesterday)).toList();
    return Option<CycleInputs>.of(day.inputs(yesterday, before, billsDue: billsDue + postedToday));
  }

  // why: BR-3 `B` covers occurrences after today only.
  static Iterable<Money> _billsAfter(RecurringRule rule, CalendarDate today, PayCycle cycle) {
    final CalendarDate first = RecurringSchedule.firstUnpostedAfter(rule.schedule, rule.nextDue, today: today);
    return RecurringSchedule.datesFrom(rule.schedule, first, through: cycle.end).map((CalendarDate _) => rule.amount);
  }

  static Money _sum(Iterable<Money> amounts) => amounts.fold(Money.zero, (Money total, Money amount) => total + amount);
}

/// What stays the same for every day of one cycle, so [inputs] can total any one day.
final class _DayTotals {
  const _DayTotals({required this.cycle, required this.settings, required this.hasIncomeRule});

  final PayCycle cycle;
  final BudgetSettings settings;
  final bool hasIncomeRule;

  /// Totals [entries] for [today], with [billsDue] still to go out after it.
  CycleInputs inputs(CalendarDate today, List<Entry> entries, {required Money billsDue}) {
    final Iterable<Entry> spent = entries.where((Entry e) => e.kind == EntryKind.spent);
    final Iterable<Entry> spentBefore = spent.where((Entry e) => e.date.isBefore(today));
    return CycleInputs(
      cycle: cycle,
      today: today,
      income: GetCycleSummary._sum(entries.where((Entry e) => e.kind == EntryKind.got).map((Entry e) => e.amount)),
      keepAside: settings.keepAside,
      billsDue: billsDue,
      spentBefore: GetCycleSummary._sum(spentBefore.map((Entry e) => e.amount)),
      spentToday: GetCycleSummary._sum(spent.where((Entry e) => e.date == today).map((Entry e) => e.amount)),
      paceSpentBefore: GetCycleSummary._sum(spentBefore.where((Entry e) => e.recurringId == null).map((Entry e) => e.amount)),
      hasIncomeRule: hasIncomeRule,
    );
  }
}
