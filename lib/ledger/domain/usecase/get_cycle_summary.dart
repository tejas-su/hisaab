import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/amount_mode.dart';
import '../entities/bill_skip.dart';
import '../entities/budget_settings.dart';
import '../entities/cycle_inputs.dart';
import '../entities/cycle_summary.dart';
import '../entities/entry.dart';
import '../entities/entry_kind.dart';
import '../entities/occurrence.dart';
import '../entities/recurring_rule.dart';
import '../entities/week_day.dart';
import '../pay_rule_schedule.dart';
import '../repository/budget_settings_repository.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';
import '../due_amounts.dart';
import '../safe_to_spend.dart';
import '../waiting_bills.dart';

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
    final _Cycle context = (
      day: _DayTotals(cycle: cycle, hasIncomeRule: income.isSome()),
      today: today,
      previousStart: _periods.cycleFor(today: cycle.start.addDays(-1), rule: payRule, monthStart: settings.monthStart).start,
      endsAtMonthEnd: _periods.endsAtMonthEnd(rule: payRule, monthStart: settings.monthStart),
    );
    return _ledger.firstLoggedOn().flatMap(
          (Option<CalendarDate> firstLogged) => _ledger.entriesBetween(cycle.start, cycle.end).flatMap(
                (List<Entry> entries) => _recurring.skipsBetween(cycle.start, today).map(
                      (List<BillSkip> skips) => _compute(
                        context,
                        (rules: rules, entries: entries, skips: skips),
                        firstLogged,
                      ),
                    ),
              ),
        );
  }

  static CycleSummary _compute(_Cycle context, _Data data, Option<CalendarDate> firstLogged) {
    final CalendarDate today = context.today;
    final PayCycle cycle = context.day.cycle;
    final List<Occurrence> waiting =
        WaitingBills.of(data.rules, entries: data.entries, skips: data.skips, today: today, cycle: cycle);
    final _Ledger ledger = (entries: data.entries, due: _due(data.rules, waiting, today, cycle));
    return SafeToSpend.compute(
      context.day.inputs(today, data.entries, ledger.due),
      earliestEntryDate: context.previousStart,
      spentThisWeek: _spentThisWeek(data.entries, today),
      yesterday: _trackedYesterday(firstLogged, today).flatMap((CalendarDate _) => _yesterday(context.day, today, ledger)),
      week: _week(context.day, today, ledger),
      endsAtMonthEnd: context.endsAtMonthEnd,
      waitingBills: waiting,
    );
  }

  // why: a changing bill is reserved at its estimate while it waits and on its later dates; a
  // card bill is never reserved, because its card buys were counted when made (D123).
  static _Due _due(List<RecurringRule> rules, List<Occurrence> waiting, CalendarDate today, PayCycle cycle) {
    final Iterable<RecurringRule> bills =
        rules.where((RecurringRule r) => r.kind == EntryKind.spent && r.amountMode != AmountMode.card);
    final Money waitingVaries = _sum(
      waiting.where((Occurrence o) => o.rule.amountMode == AmountMode.varies).map((Occurrence o) => o.rule.amount),
    );
    return (
      bills: DueAmounts.after(bills, today: today, cycle: cycle) + waitingVaries,
      savings: DueAmounts.after(rules.where((RecurringRule r) => r.kind == EntryKind.saved), today: today, cycle: cycle),
    );
  }
  // why: an app installed today back-posts salary to the cycle start, so yesterday's "saving"
  // would be money nobody tracked. Only a day the app was already in use earns the note.
  static Option<CalendarDate> _trackedYesterday(Option<CalendarDate> firstLogged, CalendarDate today) =>
      firstLogged.filter((CalendarDate day) => day.isBefore(today)).map((CalendarDate _) => today.addDays(-1));

  // why: entries are loaded from the cycle start, so a week begun last cycle counts this cycle's days only.
  // Bills sit in the pool on their day (D119), so the week counts typed spending, as each `S_today` does.
  static Money _spentThisWeek(List<Entry> entries, CalendarDate today) {
    final CalendarDate monday = _mondayOf(today);
    return _sum(
      entries
          .where((Entry e) => _isTyped(e) && !e.date.isBefore(monday) && !e.date.isAfter(today))
          .map((Entry e) => e.amount),
    );
  }

  static Option<CycleInputs> _yesterday(_DayTotals day, CalendarDate today, _Ledger ledger) {
    final CalendarDate yesterday = today.addDays(-1);
    if (!day.cycle.contains(yesterday)) {
      return const Option<CycleInputs>.none();
    }
    return Option<CycleInputs>.of(_asItStood(day, yesterday, ledger));
  }

  // why: a week begun last cycle starts at this cycle's start, as `_spentThisWeek` counts it (FR-HO-2).
  static List<WeekDay> _week(_DayTotals day, CalendarDate today, _Ledger ledger) {
    final CalendarDate monday = _mondayOf(today);
    final CalendarDate first = monday.isBefore(day.cycle.start) ? day.cycle.start : monday;
    return <WeekDay>[
      for (CalendarDate date = first; !date.isAfter(today); date = date.addDays(1))
        _weekDay(_asItStood(day, date, ledger)),
    ];
  }

  static WeekDay _weekDay(CycleInputs inputs) =>
      WeekDay(date: inputs.today, spent: inputs.spentToday, share: SafeToSpend.shareOn(inputs));

  // why: rebuilds [date] as it stood then, with the ledger as it is now. Bills and savings the
  // engine posted after [date] were still due on it, and money that came in after it hadn't
  // arrived (BR-8, BR-6a, D120).
  static CycleInputs _asItStood(_DayTotals day, CalendarDate date, _Ledger ledger) {
    Money postedSince(EntryKind kind) => _sum(
          ledger.entries
              .where((Entry e) => e.date.isAfter(date) && e.kind == kind && e.recurringId != null)
              .map((Entry e) => e.amount),
        );
    final List<Entry> upTo = ledger.entries.where((Entry e) => !e.date.isAfter(date)).toList();
    return day.inputs(
      date,
      upTo,
      (bills: ledger.due.bills + postedSince(EntryKind.spent), savings: ledger.due.savings + postedSince(EntryKind.saved)),
    );
  }

  static CalendarDate _mondayOf(CalendarDate day) => day.addDays(DateTime.monday - day.weekday);

  static bool _isTyped(Entry entry) => entry.kind == EntryKind.spent && entry.recurringId == null;

  static Money _sum(Iterable<Money> amounts) => amounts.fold(Money.zero, (Money total, Money amount) => total + amount);
}

/// What is still to post after a day: bills (`B`) and savings (`R`) (BR-3, D120).
typedef _Due = ({Money bills, Money savings});

/// What one load read: the active rules, this cycle's entries and its skips.
typedef _Data = ({List<RecurringRule> rules, List<Entry> entries, List<BillSkip> skips});

/// The cycle being summarised, as seen from [today].
typedef _Cycle = ({_DayTotals day, CalendarDate today, CalendarDate previousStart, bool endsAtMonthEnd});

/// The cycle's entries with what was due after today, for rebuilding a past day.
typedef _Ledger = ({List<Entry> entries, _Due due});

/// What stays the same for every day of one cycle, so [inputs] can total any one day.
final class _DayTotals {
  const _DayTotals({required this.cycle, required this.hasIncomeRule});

  final PayCycle cycle;
  final bool hasIncomeRule;

  /// Totals [entries] for [today], with [due] still to post after it.
  CycleInputs inputs(CalendarDate today, List<Entry> entries, _Due due) {
    final Iterable<Entry> spent = entries.where((Entry e) => e.kind == EntryKind.spent);
    final Iterable<Entry> saved = entries.where((Entry e) => e.kind == EntryKind.saved);
    final Iterable<Entry> savedToday = saved.where((Entry e) => e.date == today);
    final Iterable<Entry> spentBefore = spent.where((Entry e) => e.date.isBefore(today));
    final Iterable<Entry> spentOnDay = spent.where((Entry e) => e.date == today);
    return CycleInputs(
      cycle: cycle,
      today: today,
      income: GetCycleSummary._sum(entries.where((Entry e) => e.kind == EntryKind.got).map((Entry e) => e.amount)),
      savingsDue: due.savings,
      savedBefore: GetCycleSummary._sum(saved.where((Entry e) => e.date.isBefore(today)).map((Entry e) => e.amount)),
      savedByRuleToday: GetCycleSummary._sum(savedToday.where((Entry e) => e.recurringId != null).map((Entry e) => e.amount)),
      savedExtraToday: GetCycleSummary._sum(savedToday.where((Entry e) => e.recurringId == null).map((Entry e) => e.amount)),
      billsDue: due.bills,
      billsPostedToday: GetCycleSummary._sum(spentOnDay.where((Entry e) => e.recurringId != null).map((Entry e) => e.amount)),
      spentBefore: GetCycleSummary._sum(spentBefore.map((Entry e) => e.amount)),
      spentToday: GetCycleSummary._sum(spentOnDay.where((Entry e) => e.recurringId == null).map((Entry e) => e.amount)),
      paceSpentBefore: GetCycleSummary._sum(spentBefore.where((Entry e) => e.recurringId == null).map((Entry e) => e.amount)),
      hasIncomeRule: hasIncomeRule,
    );
  }
}
