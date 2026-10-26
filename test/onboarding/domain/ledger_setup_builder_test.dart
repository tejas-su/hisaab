import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/onboarding/domain/entities/bill_draft.dart';
import 'package:expense_tracker/onboarding/domain/entities/onboarding_draft.dart';
import 'package:expense_tracker/onboarding/domain/entities/setup_labels.dart';
import 'package:expense_tracker/onboarding/domain/ledger_setup_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fixtures/ledger/categories.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);
const SetupLabels _labels = SetupLabels(income: 'Salary', bills: <BillKind, String>{BillKind.rent: 'Rent', BillKind.phone: 'Phone'});

OnboardingDraft _draft(PayRule rule, {List<BillDraft> bills = const <BillDraft>[], int income = 45000}) =>
    OnboardingDraft(income: Money.fromMajor(income), payRule: Option<PayRule>.of(rule), bills: bills);

LedgerSetup _build(OnboardingDraft draft, {List<Category> categories = seedCategories}) =>
    LedgerSetupBuilder.build(draft, today: _today, categories: categories, labels: _labels)
        .getOrElse((Failure f) => fail(f.message));

void main() {
  group('LedgerSetupBuilder (FR-ON-5)', () {
    test('monthly salary on the 4th starts at this cycle\'s payday so it posts at once', () {
      final RecurringDraft salary = _build(_draft(const MonthlyOnDay(4))).rules.single;
      expect(salary.label, 'Salary');
      expect(salary.amount, Money.fromMajor(45000));
      expect(salary.kind, EntryKind.got);
      expect(salary.categoryId, SeedCategoryIds.salary);
      expect(salary.isIncomeSource, isTrue);
      expect(salary.schedule, const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 4)));
      expect(salary.nextDue, const CalendarDate(2026, 10, 4));
    });

    test('last-day salary starts on the previous month\'s last day', () {
      final RecurringDraft salary = _build(_draft(const LastDayOfMonth())).rules.single;
      expect(salary.schedule.lastDayOfMonth, isTrue);
      expect(salary.nextDue, const CalendarDate(2026, 9, 30));
    });

    test('weekly salary converts the monthly amount to a week (×12 ÷ 52, floored)', () {
      final RecurringDraft salary = _build(_draft(const WeeklyOn(DateTime.friday))).rules.single;
      expect(salary.amount, Money.fromMajor(10384));
      expect(salary.nextDue, const CalendarDate(2026, 10, 23));
    });

    test('income that changes gets no rule, just this month\'s money as an entry', () {
      final LedgerSetup setup = _build(_draft(const IrregularIncome()));
      expect(setup.rules, isEmpty);
      expect(
        setup.entries,
        <EntryDraft>[
          EntryDraft(
            amount: Money.fromMajor(45000),
            kind: EntryKind.got,
            categoryId: SeedCategoryIds.salary,
            date: const CalendarDate(2026, 10, 1),
          ),
        ],
      );
    });

    test('bills start at their first date in this cycle; rent goes under Home, others under Bills', () {
      final LedgerSetup setup = _build(
        _draft(const MonthlyOnDay(4), bills: <BillDraft>[
          BillDraft(kind: BillKind.rent, amount: Money.fromMajor(8200), dueDay: 5),
          BillDraft(kind: BillKind.phone, amount: Money.fromMajor(299), dueDay: 2),
        ]),
      );
      final RecurringDraft rent = setup.rules[1];
      final RecurringDraft phone = setup.rules[2];
      expect((rent.label, rent.categoryId, rent.kind, rent.nextDue),
          ('Rent', SeedCategoryIds.home, EntryKind.spent, const CalendarDate(2026, 10, 5)));
      expect((phone.label, phone.categoryId, phone.nextDue), ('Phone', SeedCategoryIds.bills, const CalendarDate(2026, 11, 2)));
    });

    test('a bill without a label falls back to its kind name', () {
      final LedgerSetup setup = _build(
        _draft(const MonthlyOnDay(4), bills: <BillDraft>[BillDraft(kind: BillKind.emi, amount: Money.fromMajor(5000), dueDay: 10)]),
      );
      expect(setup.rules.last.label, 'emi');
    });

    test('a bill on the 31st keeps its day across short months', () {
      final LedgerSetup setup = _build(
        _draft(const MonthlyOnDay(4), bills: <BillDraft>[BillDraft(kind: BillKind.rent, amount: Money.fromMajor(1), dueDay: 31)]),
      );
      expect(setup.rules.last.schedule.anchor.day, 31);
      expect(setup.rules.last.nextDue, const CalendarDate(2026, 10, 31));
    });

    final List<(String, OnboardingDraft, List<Category>)> invalid = <(String, OnboardingDraft, List<Category>)>[
      ('no pay rule', OnboardingDraft(income: Money.fromMajor(45000)), seedCategories),
      ('zero income', _draft(const MonthlyOnDay(4), income: 0), seedCategories),
      ('no salary category', _draft(const MonthlyOnDay(4)), seedCategories.where((Category c) => c.key != 'salary').toList()),
      (
        'no bills category',
        _draft(const MonthlyOnDay(4), bills: <BillDraft>[BillDraft(kind: BillKind.phone, amount: Money.fromMajor(1), dueDay: 1)]),
        seedCategories.where((Category c) => c.key != 'bills').toList(),
      ),
    ];
    for (final (String name, OnboardingDraft draft, List<Category> categories) in invalid) {
      test('returns InvalidDataFailure for $name', () {
        final Either<Failure, LedgerSetup> result =
            LedgerSetupBuilder.build(draft, today: _today, categories: categories, labels: _labels);
        expect(result.getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }
  });
}
