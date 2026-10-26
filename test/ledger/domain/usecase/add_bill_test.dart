import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeCategoryRepository categories;
  late FakeClock clock;
  late AddBill addBill;

  setUp(() {
    recurring = FakeRecurringRepository(<RecurringRule>[WorkedExample.salary]);
    categories = FakeCategoryRepository();
    clock = FakeClock(WorkedExample.now);
    addBill = AddBill(recurring: recurring, categories: categories, clock: clock);
  });

  AddBillParams params({String label = 'Electricity', int rupees = 1200, int day = 29, BillKind? kind}) => AddBillParams(
        input: BillInput(label: label, amount: Money.fromMajor(rupees), dueDay: day),
        kind: Option<BillKind>.fromNullable(kind),
      );

  Future<RecurringRule> added(AddBillParams p) async =>
      (await addBill(p).run()).getOrElse((Failure f) => fail('unexpected $f'));

  group('AddBill (FR-SE-1)', () {
    test('saves a monthly Spent rule in Bills, first due on its next date', () async {
      final RecurringRule rule = await added(params());
      expect(rule.draft, RecurringDraft(
        label: 'Electricity',
        amount: Money.fromMajor(1200),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 29)),
        nextDue: const CalendarDate(2026, 10, 29),
      ));
      expect(recurring.rules.last, rule);
    });

    test('rent goes to Home; other chips go to Bills', () async {
      expect((await added(params(label: 'Rent', kind: BillKind.rent))).categoryId, SeedCategoryIds.home);
      expect((await added(params(label: 'EMI', kind: BillKind.emi))).categoryId, SeedCategoryIds.bills);
    });

    test('a day already past this month first goes out next month (no back-posting)', () async {
      expect((await added(params(day: 5))).nextDue, const CalendarDate(2026, 11, 5));
    });

    test('a bill due today is posted today by the engine', () async {
      expect((await added(params(day: 26))).nextDue, WorkedExample.today);
    });

    test('day 31 keeps its day and clamps in a 30-day month', () async {
      clock.current = DateTime(2026, 11, 10);
      final RecurringRule rule = await added(params(day: 31));
      expect(rule.schedule.anchor, const CalendarDate(2026, 10, 31));
      expect(rule.nextDue, const CalendarDate(2026, 11, 30));
    });

    test('day 30 in February first goes out on the 28th', () async {
      clock.current = DateTime(2027, 2, 3);
      expect((await added(params(day: 30))).nextDue, const CalendarDate(2027, 2, 28));
    });

    test('an invalid bill is refused before anything is saved', () async {
      expect((await addBill(params(label: ' ')).run()).getLeft().toNullable(), isA<InvalidBillNameFailure>());
      expect(recurring.rules, <RecurringRule>[WorkedExample.salary]);
    });

    test('returns InvalidDataFailure when the seed category is missing', () async {
      final AddBill noCategories = AddBill(recurring: recurring, categories: FakeCategoryRepository(const <Category>[]), clock: clock);
      expect((await noCategories(params()).run()).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('returns the category read failure', () async {
      categories.failure = const InvalidDataFailure('boom');
      expect((await addBill(params()).run()).getLeft().toNullable(), const InvalidDataFailure('boom'));
    });

    test('returns the repository failure', () async {
      recurring.failure = const InvalidDataFailure('boom');
      expect((await addBill(params()).run()).getLeft().toNullable(), const InvalidDataFailure('boom'));
    });
  });
}
