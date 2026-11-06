import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/pay_switch.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/category.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_draft.dart';
import '../entities/recurring_rule.dart';
import '../entities/schedule.dart';
import '../entry_validator.dart';
import '../failures/ledger_failures.dart';
import '../income_amount.dart';
import '../pay_rule_schedule.dart';
import '../recurring_schedule.dart';
import '../repository/budget_settings_repository.dart';
import '../repository/category_repository.dart';
import '../repository/recurring_repository.dart';

/// A change of when the [income] comes: the new pay rule [to], the [monthly] amount (needed only
/// when there is no salary rule yet, "It changes" to a fixed day) and the [label] a new rule gets.
final class ChangePayRuleParams extends Equatable {
  const ChangePayRuleParams({required this.income, required this.to, required this.monthly, required this.label});

  final Option<RecurringRule> income;
  final PayRule to;
  final Option<Money> monthly;
  final String label;

  @override
  List<Object?> get props => <Object?>[income, to, monthly, label];
}

/// Changes when the income comes from Settings (SPEC FR-SE-1, BR-1a, DECISIONS D140).
///
/// It records the old rule as a [PaySwitch], so the current cycle keeps its start and runs to the
/// day before the first new payday, then moves the salary rule: a new day is first paid after
/// today (never today, so no pay is posted twice), "It changes" stops the rule (its past pay
/// stays), and a fixed day after "It changes" adds a rule for the month typed.
final class ChangePayRule implements UseCase<Option<RecurringRule>, ChangePayRuleParams> {
  const ChangePayRule({required this._recurring, required this._settings, required this._categories, required this._clock});

  final RecurringRepository _recurring;
  final BudgetSettingsRepository _settings;
  final CategoryRepository _categories;
  final Clock _clock;

  /// Returns [Right] with the salary rule as saved (none for "It changes"; unchanged and unwritten
  /// when [ChangePayRuleParams.to] is the current rule), or [Left] with `InvalidAmountFailure`
  /// (no or a bad monthly amount for a new rule; nothing written), `DatabaseFailure` or
  /// `InvalidDataFailure`.
  @override
  TaskEither<Failure, Option<RecurringRule>> call(ChangePayRuleParams params) {
    final PayRule from = PayRuleSchedule.payRuleOf(params.income);
    if (from == params.to) {
      return TaskEither<Failure, Option<RecurringRule>>.right(params.income);
    }
    final CalendarDate today = _clock.today();
    // why: built only when needed, so a refused amount records no switch.
    TaskEither<Failure, Unit> recordSwitch() => _settings.addPaySwitch(PaySwitch(on: today, from: from));
    return PayRuleSchedule.scheduleFor(params.to, today: today).match(
      () => recordSwitch().flatMap((Unit _) => _stop(params.income)),
      (Schedule schedule) => params.income.match(
        () => TaskEither<Failure, Money>.fromEither(_newRuleAmount(params.monthly, schedule))
            .flatMap((Money amount) => recordSwitch().flatMap((Unit _) => _add(params.label, amount, schedule, today))),
        (RecurringRule rule) => recordSwitch().flatMap((Unit _) => _move(rule, schedule, today)),
      ),
    );
  }

  TaskEither<Failure, Option<RecurringRule>> _stop(Option<RecurringRule> income) => income.match(
        () => TaskEither<Failure, Option<RecurringRule>>.right(const Option<RecurringRule>.none()),
        (RecurringRule rule) =>
            _recurring.setActive(rule.id, active: false).map((Unit _) => const Option<RecurringRule>.none()),
      );

  TaskEither<Failure, Option<RecurringRule>> _move(RecurringRule rule, Schedule schedule, CalendarDate today) => _recurring
      .update(rule.copyWith(
        schedule: schedule,
        nextDue: _firstAfter(schedule, today),
        amount: IncomeAmount.perPay(IncomeAmount.monthlyOf(rule), schedule),
      ))
      .map(Option<RecurringRule>.of);

  TaskEither<Failure, Option<RecurringRule>> _add(String label, Money amount, Schedule schedule, CalendarDate today) =>
      _categories.idOf(CategoryKeys.salary).flatMap(
            (int categoryId) => _recurring
                .add(RecurringDraft(
                  label: label,
                  amount: amount,
                  kind: EntryKind.got,
                  categoryId: categoryId,
                  schedule: schedule,
                  nextDue: _firstAfter(schedule, today),
                  isIncomeSource: true,
                ))
                .map(Option<RecurringRule>.of),
          );

  static Either<Failure, Money> _newRuleAmount(Option<Money> monthly, Schedule schedule) => monthly
      .toEither<Failure>(() => InvalidAmountFailure('A new salary rule needs an amount'))
      .flatMap(EntryValidator.validateAmount)
      .flatMap((Money month) => EntryValidator.validateAmount(IncomeAmount.perPay(month, schedule)));

  // why: this cycle's pay has already come, so the first new pay is after today, never on it.
  static CalendarDate _firstAfter(Schedule schedule, CalendarDate today) =>
      RecurringSchedule.firstOnOrAfter(schedule, today.addDays(1));
}
