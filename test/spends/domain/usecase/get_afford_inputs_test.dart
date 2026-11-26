import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/month_start.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/afford_context.dart';
import 'package:hisaab/spends/domain/usecase/get_afford_inputs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';

// FakeClock is pinned to Mon 26 Oct 2026; pay on the 4th puts it in 4 Oct to 3 Nov.
const PayCycle _nextCycle = PayCycle(start: CalendarDate(2026, 11, 4), end: CalendarDate(2026, 12, 3));

RecurringRule _rule(
  int id,
  String label,
  int rupees, {
  required EntryKind kind,
  required CalendarDate anchor,
  Frequency frequency = Frequency.monthly,
  bool isIncomeSource = false,
  AmountMode amountMode = AmountMode.fixed,
  Option<Money> target = const Option<Money>.none(),
}) =>
    RecurringRule(
      id: id,
      label: label,
      amount: Money.fromMajor(rupees),
      kind: kind,
      categoryId: 1,
      schedule: Schedule(frequency: frequency, anchor: anchor),
      nextDue: anchor,
      isIncomeSource: isIncomeSource,
      amountMode: amountMode,
      target: target,
    );

final RecurringRule _salary =
    _rule(1, 'Salary', 45000, kind: EntryKind.got, anchor: const CalendarDate(2026, 11, 4), isIncomeSource: true);
final RecurringRule _rent = _rule(2, 'Rent', 11800, kind: EntryKind.spent, anchor: const CalendarDate(2026, 11, 5));
final RecurringRule _electricity = _rule(
  3,
  'Electricity',
  1200,
  kind: EntryKind.spent,
  anchor: const CalendarDate(2026, 11, 20),
  amountMode: AmountMode.varies,
);
final RecurringRule _card = _rule(
  4,
  'Credit card',
  8000,
  kind: EntryKind.spent,
  anchor: const CalendarDate(2026, 11, 10),
  amountMode: AmountMode.card,
);

RecurringRule _saving(int id, String label, int rupees, {Option<Money> target = const Option<Money>.none()}) =>
    _rule(id, label, rupees, kind: EntryKind.saved, anchor: const CalendarDate(2026, 11, 5), target: target);

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;

  setUp(() {
    ledger = FakeLedgerRepository();
    recurring = FakeRecurringRepository();
    settings = FakeBudgetSettingsRepository();
  });

  tearDown(() => ledger.dispose());

  void addEntry(
    int rupees,
    CalendarDate date, {
    EntryKind kind = EntryKind.spent,
    CalendarDate? loggedOn,
    int? recurringId,
    int? savingId,
    bool isNotLogged = false,
  }) {
    final CalendarDate logged = loggedOn ?? date;
    ledger.entries.add(
      Entry(
        id: 100 + ledger.entries.length,
        amount: Money.fromMajor(rupees),
        kind: kind,
        categoryId: 1,
        date: date,
        createdAt: DateTime(logged.year, logged.month, logged.day, 9),
        recurringId: recurringId,
        savingId: savingId,
        isNotLogged: isNotLogged,
      ),
    );
  }

  Future<AffordContext> context([String name = '', DateTime? now]) async {
    final GetAffordInputs useCase = GetAffordInputs(
      ledger: ledger,
      recurring: recurring,
      settings: settings,
      periods: const PeriodCalculator(),
      clock: FakeClock(now ?? DateTime(2026, 10, 26, 10, 30)),
    );
    return (await useCase(name).run()).getOrElse((Failure f) => fail(f.message));
  }

  group('GetAffordInputs room by dates (BR-24 Determinism and tests, E161)', () {
    // why: pay on the 1st makes each cycle a calendar month; a ₹1,000 bill every Tuesday shows
    // that room is counted by the dates inside the next cycle, never "monthly".
    final RecurringRule payOnFirst =
        _rule(1, 'Salary', 45000, kind: EntryKind.got, anchor: const CalendarDate(2026, 12, 1), isIncomeSource: true);
    final RecurringRule tuesdays =
        _rule(2, 'Tiffin', 1000, kind: EntryKind.spent, anchor: const CalendarDate(2026, 12, 1), frequency: Frequency.weekly);

    for (final (String name, DateTime now, PayCycle next, int days, int tuesdaysIn) in <(String, DateTime, PayCycle, int, int)>[
      ('a 28-day February', DateTime(2027, 1, 15, 10), const PayCycle(start: CalendarDate(2027, 2, 1), end: CalendarDate(2027, 2, 28)), 28, 4),
      ('a 29-day leap February', DateTime(2028, 1, 15, 10), const PayCycle(start: CalendarDate(2028, 2, 1), end: CalendarDate(2028, 2, 29)), 29, 5),
      ('a 31-day March', DateTime(2027, 2, 10, 10), const PayCycle(start: CalendarDate(2027, 3, 1), end: CalendarDate(2027, 3, 31)), 31, 5),
    ]) {
      test('$name next cycle: its days, and every Tuesday inside it', () async {
        recurring.rules = <RecurringRule>[payOnFirst, tuesdays];

        final AffordContext result = await context('', now);

        expect(result.nextCycle, next);
        expect(result.days, days);
        expect(result.room, Money.fromMajor(45000 - 1000 * tuesdaysIn));
      });
    }

    // why: weekly pay with the month starting on the 1st puts four or five paydays in a month.
    final RecurringRule fridays = _rule(
      1,
      'Pay',
      10000,
      kind: EntryKind.got,
      anchor: const CalendarDate(2026, 10, 2),
      frequency: Frequency.weekly,
      isIncomeSource: true,
    );

    for (final (String name, DateTime now, PayCycle next, int paydays) in <(String, DateTime, PayCycle, int)>[
      ('November 2026 has 4 Fridays', DateTime(2026, 10, 26, 10), const PayCycle(start: CalendarDate(2026, 11, 1), end: CalendarDate(2026, 11, 30)), 4),
      ('January 2027 has 5 Fridays', DateTime(2026, 12, 10, 10), const PayCycle(start: CalendarDate(2027, 1, 1), end: CalendarDate(2027, 1, 31)), 5),
    ]) {
      test('calendar-month cycle with weekly pay: $name', () async {
        settings.settings = const BudgetSettings(monthStart: MonthStart.firstOfMonth);
        recurring.rules = <RecurringRule>[fridays];

        final AffordContext result = await context('', now);

        expect(result.nextCycle, next);
        expect(result.days, next.lengthInDays);
        expect(result.room, Money.fromMajor(10000 * paydays));
      });
    }
  });

  group('GetAffordInputs (BR-24)', () {
    test('room_counts_occurrences_in_next_cycle: bills, a changing estimate and a saving, never the card bill', () async {
      recurring.rules = <RecurringRule>[_salary, _rent, _electricity, _card, _saving(5, 'RD', 1000)];

      final AffordContext result = await context();

      expect(result.nextCycle, _nextCycle);
      expect(result.room, Money.fromMajor(31000));
      expect(result.days, 30);
      expect(result.existingSaving, const Option<RecurringRule>.none());
      expect(result.existingSetAside, Money.zero);
    });

    test('reached_saving_adds_nothing: a saving at its target subtracts ₹0', () async {
      recurring.rules = <RecurringRule>[_salary, _saving(5, 'Bike', 1000, target: Option<Money>.of(Money.fromMajor(5000)))];
      addEntry(5000, const CalendarDate(2026, 10, 5), kind: EntryKind.saved, recurringId: 5);

      expect((await context()).room, Money.fromMajor(45000));
    });

    test('partial_gap_saving_subtracts_gap: a saving ₹400 short of its target subtracts ₹400', () async {
      recurring.rules = <RecurringRule>[_salary, _saving(5, 'Bike', 1000, target: Option<Money>.of(Money.fromMajor(5000)))];
      addEntry(4600, const CalendarDate(2026, 10, 5), kind: EntryKind.saved, recurringId: 5);

      expect((await context()).room, Money.fromMajor(44600));
    });

    test('saving_filled_this_cycle_subtracts_nothing: a put-in still due this cycle reaches the target first', () async {
      final RecurringRule bike = _rule(
        5,
        'Bike',
        5000,
        kind: EntryKind.saved,
        anchor: const CalendarDate(2026, 11, 1),
        target: Option<Money>.of(Money.fromMajor(5000)),
      );
      recurring.rules = <RecurringRule>[_salary, bike];

      expect((await context()).room, Money.fromMajor(45000));
    });

    test('weekly_cycle:one week of pay, and a monthly bill outside the week is not counted', () async {
      final RecurringRule weekly = _rule(
        1,
        'Pay',
        10000,
        kind: EntryKind.got,
        anchor: const CalendarDate(2026, 10, 23),
        frequency: Frequency.weekly,
        isIncomeSource: true,
      );
      recurring.rules = <RecurringRule>[weekly, _rule(2, 'Phone', 500, kind: EntryKind.spent, anchor: const CalendarDate(2026, 11, 20))];

      final AffordContext result = await context();

      expect(result.nextCycle, const PayCycle(start: CalendarDate(2026, 10, 30), end: CalendarDate(2026, 11, 5)));
      expect(result.room, Money.fromMajor(10000));
      expect(result.days, 7);
    });

    test('irregular_income_uses_last_got: the last finished cycle\'s Got total stands in for income', () async {
      recurring.rules = <RecurringRule>[_rent];
      addEntry(25000, const CalendarDate(2026, 9, 3), kind: EntryKind.got, loggedOn: const CalendarDate(2026, 8, 20));
      addEntry(15000, const CalendarDate(2026, 9, 18), kind: EntryKind.got);
      addEntry(30000, const CalendarDate(2026, 10, 2), kind: EntryKind.got);
      addEntry(9000, const CalendarDate(2026, 9, 10));

      final AffordContext result = await context();

      expect(result.nextCycle, const PayCycle(start: CalendarDate(2026, 11, 1), end: CalendarDate(2026, 11, 30)));
      expect(result.room, Money.fromMajor(40000 - 11800));
      expect(result.days, 30);
      expect(result.usual, Option<Money>.of(Money.fromMajor(300)));
    });

    test('irregular_income_uses_last_got: no finished cycle gives no usual', () async {
      recurring.rules = <RecurringRule>[];
      addEntry(30000, const CalendarDate(2026, 10, 2), kind: EntryKind.got);

      final AffordContext result = await context();

      expect(result.room, Money.zero);
      expect(result.usual, const Option<Money>.none());
    });

    test('usual_from_last_finished_tracked_cycle: typed Spent only, over the cycle\'s days', () async {
      recurring.rules = <RecurringRule>[_salary];
      addEntry(45000, const CalendarDate(2026, 9, 4), kind: EntryKind.got, recurringId: 1, loggedOn: const CalendarDate(2026, 9, 1));
      addEntry(20000, const CalendarDate(2026, 9, 10));
      addEntry(2500, const CalendarDate(2026, 10, 3));
      addEntry(11800, const CalendarDate(2026, 9, 5), recurringId: 2);
      addEntry(3000, const CalendarDate(2026, 9, 20), isNotLogged: true);
      addEntry(900, const CalendarDate(2026, 10, 10));

      expect((await context()).usual, Option<Money>.of(Money.fromMajor(750)));
    });

    test('usual_from_last_finished_tracked_cycle: floored to the rupee', () async {
      recurring.rules = <RecurringRule>[_salary];
      addEntry(22515, const CalendarDate(2026, 9, 10), loggedOn: const CalendarDate(2026, 9, 1));

      expect((await context()).usual, Option<Money>.of(Money.fromMajor(750)));
    });

    test('usual_from_last_finished_tracked_cycle: a cycle not tracked from its start gives none', () async {
      recurring.rules = <RecurringRule>[_salary];
      addEntry(22500, const CalendarDate(2026, 9, 10));

      expect((await context()).usual, const Option<Money>.none());
    });

    test('usual_from_last_finished_tracked_cycle: a typed total of ₹0 gives none', () async {
      recurring.rules = <RecurringRule>[_salary];
      addEntry(45000, const CalendarDate(2026, 9, 4), kind: EntryKind.got, recurringId: 1, loggedOn: const CalendarDate(2026, 9, 1));
      addEntry(11800, const CalendarDate(2026, 9, 5), recurringId: 2);

      expect((await context()).usual, const Option<Money>.none());
    });

    test('existing_saving_by_name: "mac" finds "Mac", with its set aside, left out of room', () async {
      final RecurringRule mac = _saving(5, 'Mac', 5000);
      recurring.rules = <RecurringRule>[_salary, _rent, mac, _rule(6, 'mac', 700, kind: EntryKind.spent, anchor: const CalendarDate(2026, 11, 6))];
      addEntry(20000, const CalendarDate(2026, 10, 5), kind: EntryKind.saved, recurringId: 5);
      addEntry(3000, const CalendarDate(2026, 10, 12), kind: EntryKind.used, savingId: 5);

      final AffordContext result = await context(' mac ');

      expect(result.existingSaving, Option<RecurringRule>.of(mac));
      expect(result.existingSetAside, Money.fromMajor(17000));
      expect(result.room, Money.fromMajor(45000 - 11800 - 700));
    });

    test('existing_saving_by_name: an empty name matches nothing', () async {
      recurring.rules = <RecurringRule>[_salary, _saving(5, '', 1000)];

      final AffordContext result = await context();

      expect(result.existingSaving, const Option<RecurringRule>.none());
      expect(result.room, Money.fromMajor(44000));
    });

    test('the same data gives the same context', () async {
      recurring.rules = <RecurringRule>[_salary, _rent];

      expect(await context(), await context());
    });

    test('a failed read is passed on', () async {
      settings.failure = DatabaseFailure('disk');
      final GetAffordInputs useCase = GetAffordInputs(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: FakeClock(DateTime(2026, 10, 26)),
      );

      expect((await useCase('').run()).isLeft(), isTrue);
    });
  });
}
