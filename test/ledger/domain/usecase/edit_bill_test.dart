import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/domain/entities/occurrence.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late EditBill editBill;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    editBill = EditBill(recurring: recurring, categories: FakeCategoryRepository(), clock: FakeClock(WorkedExample.now));
  });

  EditBillParams params(RecurringRule rule, {String? label, int? rupees, required int day, Option<BillIcon>? icon, AmountMode? mode}) =>
      EditBillParams(
        rule: rule,
        input: BillInput(
          label: label ?? rule.label,
          amount: rupees == null ? rule.amount : Money.fromMajor(rupees),
          dueDay: day,
          icon: icon ?? rule.icon,
          amountMode: mode ?? rule.amountMode,
        ),
      );

  Future<RecurringRule> edited(EditBillParams p) async =>
      (await editBill(p).run()).getOrElse((Failure f) => fail('unexpected $f'));

  group('EditBill — Amount changes? (D123, D124)', () {
    test('fixed to card files it under the hidden card category', () async {
      final RecurringRule rule = await edited(params(WorkedExample.electricity, day: 29, mode: AmountMode.card));
      expect(rule.amountMode, AmountMode.card);
      expect(rule.categoryId, SeedCategoryIds.cardPaid);
    });

    test('card to changing files it back under Bills', () async {
      final RecurringRule card = WorkedExample.electricity.copyWith(amountMode: AmountMode.card, categoryId: SeedCategoryIds.cardPaid);
      recurring.rules = <RecurringRule>[card];
      final RecurringRule rule = await edited(params(card, day: 29, mode: AmountMode.varies));
      expect(rule.amountMode, AmountMode.varies);
      expect(rule.categoryId, SeedCategoryIds.bills);
    });

    test('fixed to changing keeps the category, schedule and next date', () async {
      final RecurringRule rule = await edited(params(WorkedExample.electricity, day: 29, mode: AmountMode.varies));
      expect(rule.categoryId, WorkedExample.electricity.categoryId);
      expect(rule.schedule, WorkedExample.electricity.schedule);
      expect(rule.nextDue, WorkedExample.electricity.nextDue);
    });

    test('switching to fixed posts at most the latest unanswered occurrence (E-f)', () async {
      final RecurringRule stale = RecurringRule(
        id: 8,
        label: 'Electricity',
        amount: Money.fromMajor(1200),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 7, 20)),
        nextDue: const CalendarDate(2026, 7, 20),
        amountMode: AmountMode.varies,
      );
      recurring.rules = <RecurringRule>[stale];
      final RecurringRule rule = await edited(params(stale, day: 20, mode: AmountMode.fixed));
      expect(rule.nextDue, const CalendarDate(2026, 10, 20));
      await PostDueRecurring(recurring: recurring, clock: FakeClock(WorkedExample.now))(const NoParams()).run();
      expect(recurring.postings.single.occurrences.map((Occurrence o) => o.date), <CalendarDate>[const CalendarDate(2026, 10, 20)]);
      expect(recurring.postings.single.occurrences.single.rule.amount, Money.fromMajor(1200));
    });

    test('switching to fixed never moves a next date already ahead', () async {
      final RecurringRule ahead = WorkedExample.electricity.copyWith(amountMode: AmountMode.varies);
      recurring.rules = <RecurringRule>[ahead];
      expect((await edited(params(ahead, day: 29, mode: AmountMode.fixed))).nextDue, const CalendarDate(2026, 10, 29));
    });

    test('returns the category read failure for a switch to card', () async {
      final FakeCategoryRepository categories = FakeCategoryRepository()..failure = DatabaseFailure('categories');
      final EditBill failing = EditBill(recurring: recurring, categories: categories, clock: FakeClock(WorkedExample.now));
      expect((await failing(params(WorkedExample.electricity, day: 29, mode: AmountMode.card)).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('EditBill (FR-SE-1; BR-9 edits change future occurrences only)', () {
    test('a new name and amount keep the rule, its category and its next date', () async {
      final RecurringRule rule = await edited(params(WorkedExample.electricity, label: 'Power', rupees: 1500, day: 29));
      expect(rule.id, WorkedExample.electricity.id);
      expect(rule.categoryId, WorkedExample.electricity.categoryId);
      expect((rule.label, rule.amount, rule.nextDue), ('Power', Money.fromMajor(1500), const CalendarDate(2026, 10, 29)));
      expect(recurring.rules.last, rule);
    });

    test('moving an unposted bill a day earlier moves its next date', () async {
      expect((await edited(params(WorkedExample.electricity, day: 28))).nextDue, const CalendarDate(2026, 10, 28));
    });

    test('a bill already posted this month moves within next month, never posting twice', () async {
      expect((await edited(params(WorkedExample.rent, day: 29))).nextDue, const CalendarDate(2026, 11, 29));
    });

    test('a day already past this month first goes out next month', () async {
      expect((await edited(params(WorkedExample.electricity, day: 2))).nextDue, const CalendarDate(2026, 11, 2));
    });

    test('moving an unposted bill to today posts it today', () async {
      expect((await edited(params(WorkedExample.electricity, day: 26))).nextDue, WorkedExample.today);
    });

    test('a stale next date from a missed run is never back-posted', () async {
      final RecurringRule stale = WorkedExample.electricity.copyWith(nextDue: const CalendarDate(2026, 9, 29));
      recurring.rules = <RecurringRule>[stale];
      expect((await edited(params(stale, day: 30))).nextDue, const CalendarDate(2026, 10, 30));
    });

    test('changing only the amount keeps next_due for day 31 in a 30-day month (Review Focus 1)', () async {
      final RecurringRule day31 = WorkedExample.electricity.copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 31)),
        nextDue: const CalendarDate(2026, 11, 30),
      );
      recurring.rules = <RecurringRule>[day31];
      final RecurringRule rule = await edited(params(day31, rupees: 1350, day: 31));
      expect((rule.amount, rule.nextDue), (Money.fromMajor(1350), const CalendarDate(2026, 11, 30)));
    });

    test('an edit that keeps the day never moves a stale next date (FR-SE-1 AC-4)', () async {
      final RecurringRule stale = WorkedExample.electricity.copyWith(nextDue: const CalendarDate(2026, 9, 29));
      recurring.rules = <RecurringRule>[stale];
      final RecurringRule rule = await edited(params(stale, rupees: 1350, day: 29));
      expect((rule.amount, rule.nextDue, rule.schedule), (Money.fromMajor(1350), const CalendarDate(2026, 9, 29), stale.schedule));
    });

    test('saves a picked icon, and none clears it (D118)', () async {
      final RecurringRule picked = await edited(params(WorkedExample.rent, day: 5, icon: const Option<BillIcon>.of(BillIcon.society)));
      expect(picked.icon, const Option<BillIcon>.of(BillIcon.society));
      expect((await edited(params(picked, day: 5, icon: const Option<BillIcon>.none()))).icon, const Option<BillIcon>.none());
    });

    test('the schedule follows the new day', () async {
      expect((await edited(params(WorkedExample.rent, day: 31))).schedule.anchor.day, 31);
    });

    test('an invalid edit is refused before anything is saved', () async {
      expect((await editBill(params(WorkedExample.rent, rupees: 0, day: 5)).run()).getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(recurring.rules, WorkedExample.rules);
    });

    test('returns RuleNotFoundFailure for a rule that was deleted', () async {
      recurring.rules = <RecurringRule>[WorkedExample.salary];
      expect((await editBill(params(WorkedExample.rent, day: 5)).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });
  });
}
