import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/month_start.dart';
import '../../core/time/pay_cycle.dart';
import '../../core/time/pay_rule.dart';
import '../../core/time/period_calculator.dart';
import '../../ledger/ledger.dart';
import 'entities/bill_draft.dart';
import 'entities/bill_kind.dart';
import 'entities/onboarding_draft.dart';
import 'entities/setup_labels.dart';

/// Turns finished onboarding answers into the rules and entries the ledger starts with (FR-ON-5).
///
/// Everything is dated from the start of the current cycle, so the recurring engine immediately
/// posts this cycle's salary and any bills already paid, and later bills count as due (BR-3).
abstract final class LedgerSetupBuilder {
  static const int _weeksPerYear = 52;
  static const int _monthsPerYear = 12;

  /// Builds the setup for [draft] on [today] using the seeded [categories].
  ///
  /// Returns [Right] with the setup, or [Left] with `InvalidDataFailure` when the pay rule is
  /// missing, the income is zero or a seed category can't be found.
  static Either<Failure, LedgerSetup> build(
    OnboardingDraft draft, {
    required CalendarDate today,
    required List<Category> categories,
    required SetupLabels labels,
  }) {
    if (draft.income.isZero) {
      return Either<Failure, LedgerSetup>.left(const InvalidDataFailure('Onboarding income is zero'));
    }
    return draft.payRule
        .toEither<Failure>(() => const InvalidDataFailure('Onboarding pay rule missing'))
        .flatMap(
          (PayRule rule) => _categoryId(categories, CategoryKeys.salary).flatMap(
            (int salaryId) => draft.bills.traverseEither((BillDraft bill) => _bill(bill, today, rule, categories, labels)).map(
                  (List<RecurringDraft> bills) => _withIncome(draft.income, rule, today, salaryId, labels.income, bills),
                ),
          ),
        );
  }

  static LedgerSetup _withIncome(
    Money income,
    PayRule rule,
    CalendarDate today,
    int salaryId,
    String label,
    List<RecurringDraft> bills,
  ) {
    final PayCycle cycle = _cycle(today, rule);
    return PayRuleSchedule.scheduleFor(rule, today: today).match(
      () => LedgerSetup(
        rules: bills,
        entries: <EntryDraft>[EntryDraft(amount: income, kind: EntryKind.got, categoryId: salaryId, date: cycle.start)],
      ),
      (Schedule schedule) => LedgerSetup(
        rules: <RecurringDraft>[
          RecurringDraft(
            label: label,
            amount: rule is WeeklyOn ? _weekly(income) : income,
            kind: EntryKind.got,
            categoryId: salaryId,
            schedule: schedule,
            nextDue: cycle.start,
            isIncomeSource: true,
          ),
          ...bills,
        ],
      ),
    );
  }

  static Either<Failure, RecurringDraft> _bill(
    BillDraft bill,
    CalendarDate today,
    PayRule rule,
    List<Category> categories,
    SetupLabels labels,
  ) {
    final Schedule schedule =
        Schedule(frequency: Frequency.monthly, anchor: RecurringSchedule.monthlyAnchor(bill.dueDay, near: today));
    final String categoryKey = bill.kind == BillKind.rent ? CategoryKeys.home : CategoryKeys.bills;
    return _categoryId(categories, categoryKey).map(
      (int categoryId) => RecurringDraft(
        label: labels.bills[bill.kind] ?? bill.kind.name,
        amount: bill.amount,
        kind: EntryKind.spent,
        categoryId: categoryId,
        schedule: schedule,
        nextDue: RecurringSchedule.firstOnOrAfter(schedule, _cycle(today, rule).start),
      ),
    );
  }

  static PayCycle _cycle(CalendarDate today, PayRule rule) =>
      const PeriodCalculator().cycleFor(today: today, rule: rule, monthStart: MonthStart.payday);

  // why: step 1 asks for money "each month"; a weekly salary is that amount spread over 52 weeks.
  static Money _weekly(Money monthly) {
    final int perMajor = monthly.currency.minorPerMajor;
    final int weeklyMajor = monthly.floorMajor * _monthsPerYear ~/ _weeksPerYear;
    return Money(weeklyMajor * perMajor, currency: monthly.currency);
  }

  static Either<Failure, int> _categoryId(List<Category> categories, String key) => Option<Category>.fromNullable(
        categories.where((Category category) => category.key == key).firstOrNull,
      ).map((Category category) => category.id).toEither<Failure>(() => InvalidDataFailure('No "$key" category'));
}
