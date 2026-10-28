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
            final List<PayCycle> cycles = _cyclesBack(today, settings, rules, params + 1);
            return _overview(
              _Viewed(cycle: cycles[params], previous: cycles[params + 1], cyclesBack: params, today: today),
              settings.keepAside,
            );
          }),
        );
  }

  /// The current cycle and the [count] before it, newest first.
  List<PayCycle> _cyclesBack(CalendarDate today, BudgetSettings settings, List<RecurringRule> rules, int count) {
    final PayRule rule = PayRuleSchedule.payRuleOf(
      Option<RecurringRule>.fromNullable(rules.where((RecurringRule r) => r.isIncomeSource).firstOrNull),
    );
    PayCycle cycleOf(CalendarDate day) => _periods.cycleFor(today: day, rule: rule, monthStart: settings.monthStart);
    return Iterable<int>.generate(count).fold(
      <PayCycle>[cycleOf(today)],
      (List<PayCycle> cycles, int _) => <PayCycle>[...cycles, cycleOf(cycles.last.start.addDays(-1))],
    );
  }

  TaskEither<Failure, SpendsOverview> _overview(_Viewed viewed, Money keepAside) => _categories.all().flatMap(
        (List<Category> categories) => _ledger.entriesBetween(viewed.previous.start, viewed.cycle.end).flatMap(
              (List<Entry> entries) => _ledger.firstLoggedOn().flatMap(
                    (Option<CalendarDate> firstLogged) => _limitOffer(viewed).map(
                      (Option<Insight> offer) => _build(viewed, keepAside, categories, entries, firstLogged, offer),
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
    Money keepAside,
    List<Category> categories,
    List<Entry> entries,
    Option<CalendarDate> firstLogged,
    Option<Insight> offer,
  ) {
    final List<Entry> current = entries.where((Entry e) => viewed.cycle.contains(e.date) && !e.date.isAfter(viewed.asOf)).toList();
    final List<Entry> previous = entries.where((Entry e) => viewed.previous.contains(e.date)).toList();
    final Money budget = _sum(entries.where((Entry e) => viewed.cycle.contains(e.date) && e.kind == EntryKind.got)) - keepAside;
    final bool previousTracked = firstLogged.filter((CalendarDate d) => !d.isAfter(viewed.previous.start)).isSome();
    final List<Insight> rules = InsightRules.evaluate(
      InsightWindow(cycle: viewed.cycle, asOf: viewed.asOf, entries: current),
      previous: previousTracked
          ? Option<InsightWindow>.of(InsightWindow(cycle: viewed.previous, asOf: viewed.previous.end, entries: previous))
          : const Option<InsightWindow>.none(),
    );
    return SpendsOverview(
      cycle: viewed.cycle,
      previous: viewed.previous,
      cyclesBack: viewed.cyclesBack,
      canGoBack: previous.isNotEmpty || firstLogged.filter((CalendarDate d) => !d.isAfter(viewed.previous.end)).isSome(),
      spent: _sum(current.where((Entry e) => e.kind == EntryKind.spent)),
      budget: budget,
      pace: PaceSeries.of(current, cycle: viewed.cycle, asOf: viewed.asOf, budget: budget),
      rows: CategoryShares.of(current, categories),
      insights: <Insight>[...rules, ...offer.match(() => const <Insight>[], (Insight o) => <Insight>[o])].take(_maxInsights).toList(),
    );
  }

  static Money _sum(Iterable<Entry> entries) => entries.fold(Money.zero, (Money total, Entry e) => total + e.amount);
}

/// The cycle being looked at, the one before it, and the day it is seen from.
final class _Viewed {
  _Viewed({required this.cycle, required this.previous, required this.cyclesBack, required CalendarDate today})
      : asOf = cyclesBack == 0 ? today : cycle.end;

  final PayCycle cycle;
  final PayCycle previous;
  final int cyclesBack;
  final CalendarDate asOf;
}
