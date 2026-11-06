import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/period_calculator.dart';
import '../../../core/usecases/use_case.dart';
import '../budget_suggester.dart';
import '../entities/budget_settings.dart';
import '../entities/category.dart';
import '../entities/entry.dart';
import '../entities/recurring_rule.dart';
import '../pay_rule_schedule.dart';
import '../repository/budget_settings_repository.dart';
import '../repository/category_repository.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';

/// Works out the "Use these limits?" offer from last cycle's spending (SPEC BR-12).
///
/// The offer is made only after a **full** cycle: the app was in use from the day that cycle
/// began. It stops once any limit is set.
final class GetSuggestedLimits implements UseCase<Option<Map<int, Money>>, NoParams> {
  const GetSuggestedLimits({
    required this._ledger,
    required this._recurring,
    required this._settings,
    required this._categories,
    required this._periods,
    required this._clock,
  });

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
  final BudgetSettingsRepository _settings;
  final CategoryRepository _categories;
  final PeriodCalculator _periods;
  final Clock _clock;

  /// Returns [Right] with a limit per category id, or [None] when there is no full cycle yet,
  /// nothing was spent in it, or a limit is already set; or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` when a read fails.
  @override
  TaskEither<Failure, Option<Map<int, Money>>> call(NoParams params) => _categories.all().flatMap(
        (List<Category> categories) => categories.any((Category c) => c.limit.isSome())
            ? TaskEither<Failure, Option<Map<int, Money>>>.right(const Option<Map<int, Money>>.none())
            : _previousCycle().flatMap(_suggestFor),
      );

  TaskEither<Failure, PayCycle> _previousCycle() => _settings.read().flatMap(
        (BudgetSettings settings) => _recurring.activeRules().map((List<RecurringRule> rules) {
          final Option<RecurringRule> income = Option<RecurringRule>.fromNullable(
            rules.where((RecurringRule rule) => rule.isIncomeSource).firstOrNull,
          );
          final PayCycle current =
              _periods.cycleFor(
                today: _clock.today(),
                rule: PayRuleSchedule.payRuleOf(income),
                monthStart: settings.monthStart,
                switches: settings.paySwitches,
              );
          return _periods.cycleFor(
            today: current.start.addDays(-1),
            rule: PayRuleSchedule.payRuleOf(income),
            monthStart: settings.monthStart,
            switches: settings.paySwitches,
          );
        }),
      );

  TaskEither<Failure, Option<Map<int, Money>>> _suggestFor(PayCycle previous) => _ledger.firstLoggedOn().flatMap(
        (Option<CalendarDate> firstLogged) => firstLogged.filter((CalendarDate day) => !day.isAfter(previous.start)).match(
              () => TaskEither<Failure, Option<Map<int, Money>>>.right(const Option<Map<int, Money>>.none()),
              (CalendarDate _) => _ledger.entriesBetween(previous.start, previous.end).map(
                    (List<Entry> entries) => Option<Map<int, Money>>.of(BudgetSuggester.suggest(entries))
                        .filter((Map<int, Money> limits) => limits.isNotEmpty),
                  ),
            ),
      );
}
