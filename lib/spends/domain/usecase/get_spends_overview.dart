import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../category_shares.dart';
import '../entities/insight.dart';
import '../entities/pace_series.dart';
import '../entities/spends_overview.dart';
import '../insight_rules.dart';
import '../month_story_rules.dart';
import '../spends_breakdown.dart';
import '../entities/month_story.dart';

/// Loads one cycle's Spends: totals, pace, *Where it went* and insights (SPEC FR-SP).
final class GetSpendsOverview implements UseCase<SpendsOverview, int> {
  const GetSpendsOverview({
    required this._ledger,
    required this._recurring,
    required this._settings,
    required this._categories,
    required this._suggestLimits,
    required this._periods,
    required this._clock,
  });

  static const int _maxInsights = 3;

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
  final BudgetSettingsRepository _settings;
  final CategoryRepository _categories;
  final GetSuggestedLimits _suggestLimits;
  final PeriodCalculator _periods;
  final Clock _clock;

  /// Loads the cycle [params] cycles before the current one (0 is the current cycle).
  ///
  /// Returns [Right] with the overview, or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` when a read fails.
  @override
  TaskEither<Failure, SpendsOverview> call(int params) {
    final CalendarDate today = _clock.today();
    return _settings.read().flatMap(
          (BudgetSettings settings) => _recurring.activeRules().flatMap((List<RecurringRule> rules) {
            final List<PayCycle> cycles = _cyclesBack(today, settings, rules, params + SpendsBreakdown.stripCycles);
            final _Viewed viewed = _Viewed(
              cycle: cycles[params],
              previous: cycles[params + 1],
              cyclesBack: params,
              today: today,
              strip: <StripCycle>[
                for (int back = params; back < params + SpendsBreakdown.stripCycles; back++) (cycle: cycles[back], cyclesBack: back),
              ],
            );
            return _overview(viewed, (savings: _savingsDue(viewed, rules), bills: _billsDue(viewed, rules)));
          }),
        );
  }

  /// The current cycle and the [count] before it, newest first.
  List<PayCycle> _cyclesBack(CalendarDate today, BudgetSettings settings, List<RecurringRule> rules, int count) {
    final PayRule rule = PayRuleSchedule.payRuleOf(
      Option<RecurringRule>.fromNullable(rules.where((RecurringRule r) => r.isIncomeSource).firstOrNull),
    );
    PayCycle cycleOf(CalendarDate day) =>
        _periods.cycleFor(today: day, rule: rule, monthStart: settings.monthStart, switches: settings.paySwitches);
    return Iterable<int>.generate(count).fold(
      <PayCycle>[cycleOf(today)],
      (List<PayCycle> cycles, int _) => <PayCycle>[...cycles, cycleOf(cycles.last.start.addDays(-1))],
    );
  }

  // why: `K` is computed (D120): a saving still to come this cycle is reserved like a bill. A past
  // cycle has nothing still to come.
  static Money _savingsDue(_Viewed viewed, List<RecurringRule> rules) => viewed.cyclesBack == 0
      ? DueAmounts.after(rules.where((RecurringRule r) => r.kind == EntryKind.saved), today: viewed.asOf, cycle: viewed.cycle)
      : Money.zero;

  // why: the steady line steps up by each bill on its day (D129). A card bill is never reserved,
  // since its card buys were counted when made (D123); a past cycle has nothing still to come.
  static List<DatedAmount> _billsDue(_Viewed viewed, List<RecurringRule> rules) => viewed.cyclesBack == 0
      ? DueAmounts.datedAfter(
          rules.where((RecurringRule r) => r.kind == EntryKind.spent && r.amountMode != AmountMode.card),
          today: viewed.asOf,
          cycle: viewed.cycle,
        )
      : const <DatedAmount>[];

  TaskEither<Failure, SpendsOverview> _overview(_Viewed viewed, _Due due) => _categories.all().flatMap(
        (List<Category> categories) => _ledger.entriesBetween(viewed.strip.last.cycle.start, viewed.cycle.end).flatMap(
              (List<Entry> entries) => _ledger.firstLoggedOn().flatMap(
                    (Option<CalendarDate> firstLogged) => _limitOffer(viewed).map(
                      (Option<Insight> offer) => _build(viewed, due, categories, entries, firstLogged, offer),
                    ),
                  ),
            ),
      );

  TaskEither<Failure, Option<Insight>> _limitOffer(_Viewed viewed) => viewed.cyclesBack == 0
      ? _suggestLimits(const NoParams()).map(
          (Option<Map<int, Money>> limits) => limits.flatMap((Map<int, Money> l) => Option<Insight>.of(LimitOffer(limits: l))),
        )
      : TaskEither<Failure, Option<Insight>>.right(const Option<Insight>.none());

  static SpendsOverview _build(
    _Viewed viewed,
    _Due due,
    List<Category> categories,
    List<Entry> entries,
    Option<CalendarDate> firstLogged,
    Option<Insight> offer,
  ) {
    final List<Entry> current = entries.where((Entry e) => viewed.cycle.contains(e.date) && !e.date.isAfter(viewed.asOf)).toList();
    final List<Entry> previous = entries.where((Entry e) => viewed.previous.contains(e.date)).toList();
    final Money saved = _sum(current.where((Entry e) => e.kind == EntryKind.saved));
    final Money budget =
        _sum(entries.where((Entry e) => viewed.cycle.contains(e.date) && e.kind == EntryKind.got)) - saved - due.savings;
    final bool previousTracked = firstLogged.filter((CalendarDate d) => !d.isAfter(viewed.previous.start)).isSome();
    final InsightWindow currentWindow = InsightWindow(cycle: viewed.cycle, asOf: viewed.asOf, entries: current);
    final Option<InsightWindow> previousWindow = previousTracked
        ? Option<InsightWindow>.of(InsightWindow(cycle: viewed.previous, asOf: viewed.previous.end, entries: previous))
        : const Option<InsightWindow>.none();
    final List<Insight> rules = InsightRules.evaluate(currentWindow, previous: previousWindow);
    return SpendsOverview(
      cycle: viewed.cycle,
      previous: viewed.previous,
      cyclesBack: viewed.cyclesBack,
      canGoBack: previous.isNotEmpty || firstLogged.filter((CalendarDate d) => !d.isAfter(viewed.previous.end)).isSome(),
      spent: _sum(current.where((Entry e) => e.kind == EntryKind.spent && !e.isNotLogged)),
      budget: budget,
      saved: saved,
      notLogged: _sum(current.where((Entry e) => e.kind == EntryKind.spent && e.isNotLogged)),
      pace: PaceSeries.of(current, cycle: viewed.cycle, asOf: viewed.asOf, budget: budget, billsDue: due.bills, isCurrent: viewed.cyclesBack == 0),
      rows: CategoryShares.of(current, categories),
      insights: <Insight>[...rules, ...offer.match(() => const <Insight>[], (Insight o) => <Insight>[o])].take(_maxInsights).toList(),
      story: _story(viewed, StoryWindow(
        cycle: viewed.cycle,
        previous: viewed.previous,
        entries: current,
        previousEntries: previous,
        previousTracked: previousTracked,
        categories: categories,
      )),
      split: SpendsBreakdown.split(current),
      comparison: previousWindow.flatMap((InsightWindow before) => SpendsBreakdown.comparison(currentWindow, before)),
      details: SpendsBreakdown.details(currentWindow, previous: previousWindow),
      strip: SpendsBreakdown.strip(viewed.strip, entries: entries, today: viewed.today, firstLogged: firstLogged),
      showsStoryRow: viewed.cyclesBack == 0 &&
          MonthStoryRules.showsRow(viewed.cycle, today: viewed.today) &&
          MonthStoryRules.hasStory(viewed.previous, today: viewed.today, entryCount: previous.length),
    );
  }

  // why: only a finished cycle has a story of its own; the current one points back with a row.
  static Option<MonthStory> _story(_Viewed viewed, StoryWindow window) =>
      viewed.cyclesBack > 0 && MonthStoryRules.hasStory(viewed.cycle, today: viewed.today, entryCount: window.entries.length)
          ? Option<MonthStory>.of(MonthStoryRules.of(window))
          : const Option<MonthStory>.none();

  static Money _sum(Iterable<Entry> entries) => entries.fold(Money.zero, (Money total, Entry e) => total + e.amount);
}

/// What rules still have to post in the cycle: savings (`R`, D120) and bills on their days (D129).
typedef _Due = ({Money savings, List<DatedAmount> bills});

/// The cycle being looked at, the one before it, and the day it is seen from.
final class _Viewed {
  _Viewed({required this.cycle, required this.previous, required this.cyclesBack, required this.today, required this.strip})
      : asOf = cyclesBack == 0 ? today : cycle.end;

  final PayCycle cycle;
  final PayCycle previous;
  final int cyclesBack;
  final CalendarDate today;
  final CalendarDate asOf;

  /// The months strip's window, newest first (BR-21).
  final List<StripCycle> strip;
}
