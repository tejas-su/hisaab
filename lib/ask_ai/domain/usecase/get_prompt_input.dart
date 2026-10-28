import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/prompt_input.dart';

/// Loads what the Ask AI prompt needs for a cycle and the two before it (SPEC BR-15), so the
/// period chips can switch without reading again. For the current cycle it also loads Home's
/// summary, so the prompt states the same numbers the hero shows.
final class GetPromptInput implements UseCase<PromptInput, PayCycle> {
  const GetPromptInput({
    required this._ledger,
    required this._recurring,
    required this._settings,
    required this._categories,
    required this._periods,
    required this._clock,
  });

  static const int _cycles = 3;

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
  final BudgetSettingsRepository _settings;
  final CategoryRepository _categories;
  final PeriodCalculator _periods;
  final Clock _clock;

  /// Loads the input for [params], the cycle Spends was showing.
  ///
  /// Returns [Right] with the input, or [Left] with `DatabaseFailure` or `InvalidDataFailure`
  /// when a read fails.
  @override
  TaskEither<Failure, PromptInput> call(PayCycle params) {
    final CalendarDate today = _clock.today();
    return _settings.read().flatMap(
      (BudgetSettings settings) => _recurring.activeRules().flatMap((List<RecurringRule> rules) {
        final Option<RecurringRule> income = Option<RecurringRule>.fromNullable(
          rules.where((RecurringRule r) => r.isIncomeSource).firstOrNull,
        );
        final PayRule payRule = PayRuleSchedule.payRuleOf(income);
        final List<PayCycle> cycles = Iterable<int>.generate(_cycles - 1).fold(
          <PayCycle>[params],
          (List<PayCycle> cycles, int _) => <PayCycle>[
            ...cycles,
            _periods.cycleFor(today: cycles.last.start.addDays(-1), rule: payRule, monthStart: settings.monthStart),
          ],
        );
        final CalendarDate to = params.end.isAfter(today) ? today : params.end;
        return _categories.all().flatMap(
          (List<Category> categories) => _ledger
              .entriesBetween(cycles.last.start, to)
              .flatMap(
                (List<Entry> entries) => _summary(params, today).map(
                  (Option<CycleSummary> summary) => PromptInput(
                    cycles: cycles,
                    today: today,
                    incomeRule: income,
                    payRule: payRule,
                    bills: rules.where((RecurringRule r) => r.kind == EntryKind.spent).toList(),
                    categories: categories,
                    entries: entries,
                    summary: summary,
                    keepAside: settings.keepAside,
                  ),
                ),
              ),
        );
      }),
    );
  }

  // why: Home's own use case, so the prompt's numbers can never differ from the hero's. Only
  // the cycle holding today has a "today" to state.
  TaskEither<Failure, Option<CycleSummary>> _summary(PayCycle shown, CalendarDate today) => shown.contains(today)
      ? GetCycleSummary(ledger: _ledger, recurring: _recurring, settings: _settings, periods: _periods, clock: _clock)(
          const NoParams(),
        ).map(Option<CycleSummary>.of)
      : TaskEither<Failure, Option<CycleSummary>>.right(const Option<CycleSummary>.none());
}
