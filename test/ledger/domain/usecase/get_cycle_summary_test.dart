import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/month_start.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/domain/entities/amount_mode.dart';
import 'package:expense_tracker/ledger/domain/entities/bill_skip.dart';
import 'package:expense_tracker/ledger/domain/entities/budget_settings.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_state.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_summary.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/range_forecast.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';
import 'package:expense_tracker/ledger/domain/entities/week_day.dart';
import 'package:expense_tracker/ledger/domain/entities/yesterday_saving.dart';
import 'package:expense_tracker/ledger/domain/usecase/get_cycle_summary.dart';
import 'package:expense_tracker/core/time/pay_switch.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late FakeClock clock;
  late GetCycleSummary getCycleSummary;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    clock = FakeClock(WorkedExample.now);
    getCycleSummary = GetCycleSummary(
      ledger: ledger,
      recurring: recurring,
      settings: settings,
      periods: const PeriodCalculator(),
      clock: clock,
    );
  });

  tearDown(() => ledger.dispose());

  Future<CycleSummary> summary() async =>
      (await getCycleSummary(const NoParams()).run()).getOrElse((Failure failure) => fail(failure.message));

  void addEntry(int rupees, CalendarDate date, {EntryKind kind = EntryKind.spent, int? recurringId}) => ledger.entries.add(
        Entry(
          id: 100 + ledger.entries.length,
          amount: Money.fromMajor(rupees),
          kind: kind,
          categoryId: 1,
          date: date,
          createdAt: DateTime(date.year, date.month, date.day, 12),
          recurringId: recurringId,
        ),
      );

  void setToday(CalendarDate day) => clock.current = DateTime(day.year, day.month, day.day, 10);

  group('GetCycleSummary', () {
    test('reproduces the SPEC worked example from ledger data', () async {
      final CycleSummary result = await summary();
      expect(result.cycle, const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)));
      expect(result.pool, Money.fromMajor(16650));
      expect(result.todayShare, Money.fromMajor(1850));
      expect(result.safeToday, Money.fromMajor(1430));
      expect(result.state, const OnTrack());
      expect(result.forecast, LastsTillPayday(Money.fromMajor(9300)));
    });

    test('allows entries back to the start of the previous cycle (BR-10)', () async {
      expect((await summary()).earliestEntryDate, const CalendarDate(2026, 9, 4));
    });

    test('a bill not yet posted but due after the cycle is not counted', () async {
      // Rent's next date (5 Nov) is after the cycle ends (3 Nov), so B is only electricity.
      expect((await summary()).pool, Money.fromMajor(16650));
    });

    test('a bill whose next date was missed still counts its later dates in the cycle', () async {
      recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        RecurringRule(
          id: 3,
          label: 'Electricity',
          amount: Money.fromMajor(1200),
          kind: WorkedExample.electricity.kind,
          categoryId: WorkedExample.electricity.categoryId,
          schedule: WorkedExample.electricity.schedule,
          nextDue: const CalendarDate(2026, 9, 29),
        ),
      ];
      expect((await summary()).pool, Money.fromMajor(16650));
    });

    test('My month starts on the 1st: cycles follow the calendar month', () async {
      settings.settings = const BudgetSettings(monthStart: MonthStart.firstOfMonth);
      final CycleSummary result = await summary();
      expect(result.cycle, const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)));
      expect(result.earliestEntryDate, const CalendarDate(2026, 9, 1));
      expect(result.endsAtMonthEnd, isTrue);
    });

    test('a payday cycle does not end at month end (D116)', () async {
      expect((await summary()).endsAtMonthEnd, isFalse);
    });

    test('no salary rule: calendar month, and no income is the NoIncome state (E10)', () async {
      recurring.rules = <RecurringRule>[];
      ledger.entries.removeWhere((Entry e) => e.recurringId == 1);
      final CycleSummary result = await summary();
      expect(result.cycle.start, const CalendarDate(2026, 10, 1));
      expect(result.state, const NoIncome());
    });

    test('money saved earlier in the cycle reduces the pool (D120)', () async {
      addEntry(1650, const CalendarDate(2026, 10, 10), kind: EntryKind.saved);
      expect((await summary()).pool, Money.fromMajor(15000));
    });

    final List<(String, void Function())> failures = <(String, void Function())>[
      ('settings', () => settings.failure = DatabaseFailure('settings')),
      ('rules', () => recurring.failure = DatabaseFailure('rules')),
      ('entries', () => ledger.failure = DatabaseFailure('entries')),
    ];
    for (final (String name, void Function() breakIt) in failures) {
      test('returns DatabaseFailure when reading $name fails', () async {
        breakIt();
        final Either<Failure, CycleSummary> result = await getCycleSummary(const NoParams()).run();
        expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
      });
    }
  });

  group('GetCycleSummary — savings (D120)', () {
    RecurringRule rdOn(int day, CalendarDate nextDue) => RecurringRule(
          id: WorkedExample.rd.id,
          label: WorkedExample.rd.label,
          amount: WorkedExample.rd.amount,
          kind: EntryKind.saved,
          categoryId: WorkedExample.rd.categoryId,
          schedule: Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, day)),
          nextDue: nextDue,
        );

    test('an RD posted on the 10th leaves ₹1,294 for today', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      addEntry(5000, const CalendarDate(2026, 10, 10), kind: EntryKind.saved, recurringId: WorkedExample.rd.id);
      final CycleSummary s = await summary();
      expect(s.pool, Money.fromMajor(11650));
      expect(s.todayShare, Money.fromMajor(1294));
      expect(s.safeToday, Money.fromMajor(874));
      expect(s.spentToday, Money.fromMajor(420));
    });

    test('the pool doesn\'t move on the RD\'s day', () async {
      setToday(const CalendarDate(2026, 10, 25));
      recurring.rules = <RecurringRule>[...WorkedExample.rules, rdOn(26, const CalendarDate(2026, 10, 26))];
      expect((await summary()).pool, Money.fromMajor(11650));
      setToday(const CalendarDate(2026, 10, 26));
      recurring.rules = <RecurringRule>[...WorkedExample.rules, rdOn(26, const CalendarDate(2026, 11, 26))];
      addEntry(5000, const CalendarDate(2026, 10, 26), kind: EntryKind.saved, recurringId: WorkedExample.rd.id);
      expect((await summary()).pool, Money.fromMajor(11650));
    });

    test('₹500 put in today: share ₹1,294, tomorrow ₹1,341', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      addEntry(5000, const CalendarDate(2026, 10, 10), kind: EntryKind.saved, recurringId: WorkedExample.rd.id);
      addEntry(500, WorkedExample.today, kind: EntryKind.saved);
      final CycleSummary s = await summary();
      expect(s.todayShare, Money.fromMajor(1294));
      expect(s.tomorrowShare, Option<Money>.of(Money.fromMajor(1341)));
      expect(s.spentToday, Money.fromMajor(420));
      expect(s.spentThisWeek, Money.fromMajor(420));
    });

    test('an RD posted today was still to come yesterday (BR-8)', () async {
      setToday(const CalendarDate(2026, 10, 27));
      recurring.rules = <RecurringRule>[...WorkedExample.rules, rdOn(27, const CalendarDate(2026, 11, 27))];
      addEntry(5000, const CalendarDate(2026, 10, 27), kind: EntryKind.saved, recurringId: WorkedExample.rd.id);
      expect(
        (await summary()).savedYesterday,
        Option<YesterdaySaving>.of(YesterdaySaving(saved: Money.fromMajor(874), eachDayMore: Money.fromMajor(109))),
      );
    });

    test('deleting this month\'s posted RD gives its money back and nothing re-posts it', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      final CycleSummary s = await summary();
      expect(s.pool, Money.fromMajor(16650));
      expect(s.todayShare, Money.fromMajor(1850));
    });
  });

  group('GetCycleSummary — changing and card bills (D123)', () {
    const CalendarDate oct26 = CalendarDate(2026, 10, 26);
    RecurringRule bill(AmountMode mode, {CalendarDate due = oct26, int rupees = 1200}) => RecurringRule(
          id: 3,
          label: mode == AmountMode.card ? 'Credit card' : 'Electricity',
          amount: Money.fromMajor(rupees),
          kind: EntryKind.spent,
          categoryId: 5,
          schedule: Schedule(frequency: Frequency.monthly, anchor: due),
          nextDue: due,
          amountMode: mode,
        );
    void useRules(RecurringRule extra) => recurring.rules = <RecurringRule>[WorkedExample.salary, WorkedExample.rent, extra];

    test('a changing bill due today waits at its estimate (spec example 2)', () async {
      useRules(bill(AmountMode.varies));
      final CycleSummary result = await summary();
      expect(result.pool, Money.fromMajor(16650));
      expect(result.todayShare, Money.fromMajor(1850));
      expect(result.safeToday, Money.fromMajor(1430));
      expect(result.waitingBills.single.date, oct26);
    });

    test('entering it moves it from B to today\'s bills: ₹1,401 (spec example 2)', () async {
      useRules(bill(AmountMode.varies));
      addEntry(1460, oct26, recurringId: 3);
      final CycleSummary result = await summary();
      expect(result.pool, Money.fromMajor(16390));
      expect(result.todayShare, Money.fromMajor(1821));
      expect(result.safeToday, Money.fromMajor(1401));
      expect(result.waitingBills, isEmpty);
    });

    test('deleting an entered bill puts it back in B and on the waiting list', () async {
      useRules(bill(AmountMode.varies));
      addEntry(1460, oct26, recurringId: 3);
      await summary();
      ledger.entries.removeWhere((Entry e) => e.recurringId == 3);
      final CycleSummary result = await summary();
      expect(result.pool, Money.fromMajor(16650));
      expect(result.todayShare, Money.fromMajor(1850));
      expect(result.waitingBills, hasLength(1));
    });

    test('a card bill paid today leaves pool, share and hero unchanged (spec example 4)', () async {
      useRules(bill(AmountMode.card, rupees: 8000));
      final CycleSummary waiting = await summary();
      addEntry(8000, oct26, kind: EntryKind.cardPaid, recurringId: 3);
      final CycleSummary paid = await summary();
      expect(waiting.pool, Money.fromMajor(17850));
      expect(paid.pool, waiting.pool);
      expect(paid.todayShare, waiting.todayShare);
      expect(paid.spentToday, waiting.spentToday);
      expect(paid.safeToday, waiting.safeToday);
      expect(waiting.waitingBills, hasLength(1));
      expect(paid.waitingBills, isEmpty);
    });

    test('a card bill due later is never reserved', () async {
      useRules(bill(AmountMode.card, due: const CalendarDate(2026, 10, 30), rupees: 8000));
      expect((await summary()).pool, Money.fromMajor(17850));
    });

    test('a skipped bill leaves B and stops waiting', () async {
      useRules(bill(AmountMode.varies));
      recurring.skips = const <BillSkip>[BillSkip(ruleId: 3, date: oct26)];
      final CycleSummary result = await summary();
      expect(result.pool, Money.fromMajor(17850));
      expect(result.waitingBills, isEmpty);
    });

    test('a future changing bill is in B at its estimate and not waiting', () async {
      useRules(bill(AmountMode.varies, due: const CalendarDate(2026, 10, 30)));
      final CycleSummary result = await summary();
      expect(result.pool, Money.fromMajor(16650));
      expect(result.waitingBills, isEmpty);
    });

    test('a day moved later after this month was entered reserves nothing more', () async {
      useRules(bill(AmountMode.varies, due: const CalendarDate(2026, 10, 30)));
      addEntry(1460, const CalendarDate(2026, 10, 20), recurringId: 3);
      final CycleSummary result = await summary();
      expect(result.pool, Money.fromMajor(17850 - 1460));
      expect(result.waitingBills, isEmpty);
    });

    test('an entry from earlier in the month, in the last cycle, still answers a moved day', () async {
      useRules(bill(AmountMode.varies, due: oct26).copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 11, 5)),
        nextDue: const CalendarDate(2026, 11, 5),
      ));
      setToday(const CalendarDate(2026, 11, 5));
      addEntry(45000, const CalendarDate(2026, 11, 4), kind: EntryKind.got);
      addEntry(1460, const CalendarDate(2026, 11, 1), recurringId: 3);
      final CycleSummary result = await summary();
      expect(result.waitingBills, isEmpty);
    });

    test('returns DatabaseFailure when reading skips fails', () async {
      useRules(bill(AmountMode.varies));
      recurring.skipsFailure = DatabaseFailure('skips');
      expect((await getCycleSummary(const NoParams()).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('GetCycleSummary — bills on their day (D119)', () {
    // Thu 29 Oct, electricity ₹1,200 posted today. S_prev = ₹27,570 (₹27,150 + the ₹420 of 26 Oct);
    // rent is next due 5 Nov, after the cycle, so B = 0.
    // D119: P = 45,000 − 27,570 − 1,200 = 16,230 over 6 days → A = ₹2,705, spent today ₹0.
    // Old rule: A = floor(17,430 / 6) = ₹2,905 with ₹1,200 "spent today", so the hero read ₹1,705.
    test('a bill posted on its day comes out of the pool, not today (worked example, 29 Oct)', () async {
      setToday(const CalendarDate(2026, 10, 29));
      addEntry(1200, const CalendarDate(2026, 10, 29), recurringId: WorkedExample.electricity.id);
      recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        WorkedExample.rent,
        WorkedExample.electricity.copyWith(nextDue: const CalendarDate(2026, 11, 29)),
      ];
      final CycleSummary s = await summary();
      expect(s.todayShare, Money.fromMajor(2705));
      expect(s.spentToday, Money.zero);
    });

    test('salary posted today is income, not a bill', () async {
      final Money poolBefore = (await summary()).pool;
      addEntry(5000, WorkedExample.today, kind: EntryKind.got, recurringId: WorkedExample.salary.id);
      final CycleSummary s = await summary();
      expect(s.spentToday, Money.fromMajor(420));
      expect(s.pool, poolBefore + Money.fromMajor(5000));
    });

    test('a bill posted on a past day still counts in spent before', () async {
      addEntry(1200, const CalendarDate(2026, 10, 20));
      final CycleSummary typed = await summary();
      ledger.entries.removeLast();
      addEntry(1200, const CalendarDate(2026, 10, 20), recurringId: WorkedExample.electricity.id);
      final CycleSummary posted = await summary();
      expect(posted.pool, typed.pool);
      expect(posted.todayShare, typed.todayShare);
    });

    test('this week leaves out bills posted this week', () async {
      addEntry(1200, WorkedExample.today, recurringId: WorkedExample.electricity.id);
      expect((await summary()).spentThisWeek, Money.fromMajor(420));
    });

    test('a past week day with a bill posted on it shows only typed spending', () async {
      setToday(const CalendarDate(2026, 10, 28));
      addEntry(1200, const CalendarDate(2026, 10, 27), recurringId: WorkedExample.electricity.id);
      final List<WeekDay> week = (await summary()).week;
      expect(week[1].date, const CalendarDate(2026, 10, 27));
      expect(week[1].spent, Money.zero);
    });
  });

  group('GetCycleSummary — this week (FR-HO-2)', () {
    test('worked example: 7 × ₹1,850 − ₹420 = ₹12,530 safe this week', () async {
      expect((await summary()).safeThisWeek, Money.fromMajor(12530));
    });

    test('Monday is the week start, so Sunday\'s spending is last week\'s', () async {
      addEntry(500, const CalendarDate(2026, 10, 25));
      expect((await summary()).spentThisWeek, Money.fromMajor(420));
    });

    test('entries dated after today are not counted yet', () async {
      setToday(const CalendarDate(2026, 10, 19));
      expect((await summary()).spentThisWeek, Money.zero);
    });

    test('counts every day from Monday to today', () async {
      setToday(const CalendarDate(2026, 10, 28));
      addEntry(300, const CalendarDate(2026, 10, 27));
      addEntry(100, const CalendarDate(2026, 10, 28));
      expect((await summary()).spentThisWeek, Money.fromMajor(820));
    });

    test('a week that began in the last cycle counts only this cycle\'s days', () async {
      // Sun 4 Oct is payday; that week's Monday (28 Sep) was in the previous cycle.
      setToday(const CalendarDate(2026, 10, 4));
      addEntry(700, const CalendarDate(2026, 10, 1));
      expect((await summary()).spentThisWeek, Money.zero);
    });

    test('Got entries never count as spent', () async {
      addEntry(900, WorkedExample.today, kind: EntryKind.got);
      expect((await summary()).spentThisWeek, Money.fromMajor(420));
    });
  });

  group('GetCycleSummary — week days as they stood (BR-6a)', () {
    Future<Money> shareOn(CalendarDate day) async {
      setToday(day);
      return (await summary()).todayShare;
    }

    test('worked example, a Monday: the week is today alone, with its share and spending', () async {
      expect((await summary()).week, <WeekDay>[
        WeekDay(date: WorkedExample.today, spent: Money.fromMajor(420), share: Money.fromMajor(1850)),
      ]);
    });

    test('each past day keeps the share it had on that day, and its own spending', () async {
      addEntry(2310, const CalendarDate(2026, 10, 27));
      addEntry(980, const CalendarDate(2026, 10, 28));
      final List<Money> shares = <Money>[
        await shareOn(const CalendarDate(2026, 10, 26)),
        await shareOn(const CalendarDate(2026, 10, 27)),
        await shareOn(const CalendarDate(2026, 10, 28)),
      ];
      setToday(const CalendarDate(2026, 10, 28));
      final List<WeekDay> week = (await summary()).week;
      expect(week.map((WeekDay d) => d.date), const <CalendarDate>[
        CalendarDate(2026, 10, 26),
        CalendarDate(2026, 10, 27),
        CalendarDate(2026, 10, 28),
      ]);
      expect(week.map((WeekDay d) => d.share), shares);
      expect(week.map((WeekDay d) => d.spent), <Money>[Money.fromMajor(420), Money.fromMajor(2310), Money.fromMajor(980)]);
    });

    test('the last day is today, matching the hero', () async {
      setToday(const CalendarDate(2026, 10, 28));
      final CycleSummary result = await summary();
      expect(result.week.last, WeekDay(date: result.today, spent: result.spentToday, share: result.todayShare));
    });

    test('a bill posted after a past day was still due on it', () async {
      final Money monday = await shareOn(WorkedExample.today);
      setToday(const CalendarDate(2026, 10, 29));
      addEntry(1200, const CalendarDate(2026, 10, 29), recurringId: WorkedExample.electricity.id);
      recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        WorkedExample.rent,
        RecurringRule(
          id: WorkedExample.electricity.id,
          label: WorkedExample.electricity.label,
          amount: WorkedExample.electricity.amount,
          kind: WorkedExample.electricity.kind,
          categoryId: WorkedExample.electricity.categoryId,
          schedule: WorkedExample.electricity.schedule,
          nextDue: const CalendarDate(2026, 11, 29),
        ),
      ];
      expect((await summary()).week.first.share, monday);
    });

    test('money that came in after a past day was not part of its share', () async {
      final Money monday = await shareOn(WorkedExample.today);
      addEntry(900, const CalendarDate(2026, 10, 27), kind: EntryKind.got);
      setToday(const CalendarDate(2026, 10, 28));
      expect((await summary()).week.first.share, monday);
    });

    test('a back-dated entry changes that day and the days after it, not the days before', () async {
      setToday(const CalendarDate(2026, 10, 28));
      final List<WeekDay> before = (await summary()).week;
      addEntry(600, const CalendarDate(2026, 10, 27));
      final List<WeekDay> after = (await summary()).week;
      expect(after[0], before[0]);
      expect(after[1].spent, before[1].spent + Money.fromMajor(600));
      expect(after[2].share, isNot(before[2].share));
    });

    test('a week across a month end runs Monday to today', () async {
      setToday(const CalendarDate(2026, 11, 1));
      expect((await summary()).week.map((WeekDay d) => d.date), <CalendarDate>[
        for (int i = 0; i < 7; i++) const CalendarDate(2026, 10, 26).addDays(i),
      ]);
    });

    test('a week that began in the last cycle starts at the cycle start', () async {
      setToday(const CalendarDate(2026, 10, 4));
      expect((await summary()).week.map((WeekDay d) => d.date), const <CalendarDate>[CalendarDate(2026, 10, 4)]);
    });

    test('entries dated after today are not in the week', () async {
      addEntry(500, const CalendarDate(2026, 10, 27));
      expect((await summary()).week.map((WeekDay d) => d.date), const <CalendarDate>[WorkedExample.today]);
    });
  });

  group('GetCycleSummary — saved yesterday (BR-8)', () {
    test('worked example: nothing spent on Sun 25 Oct saves its ₹1,665 share, ₹185 more a day', () async {
      expect(
        (await summary()).savedYesterday,
        Option<YesterdaySaving>.of(YesterdaySaving(saved: Money.fromMajor(1665), eachDayMore: Money.fromMajor(185))),
      );
    });

    test('yesterday\'s spending is taken off yesterday\'s share', () async {
      addEntry(1365, const CalendarDate(2026, 10, 25));
      expect((await summary()).savedYesterday.map((YesterdaySaving s) => s.saved), Option<Money>.of(Money.fromMajor(300)));
    });

    test('money that came in today was not part of yesterday\'s share', () async {
      addEntry(900, WorkedExample.today, kind: EntryKind.got);
      expect((await summary()).savedYesterday.map((YesterdaySaving s) => s.saved), Option<Money>.of(Money.fromMajor(1665)));
    });

    test('a bill posted today was still due yesterday', () async {
      // Thu 29 Oct: electricity posted today. Yesterday P = 45,000 − 1,200 − 27,570 over 7 days.
      setToday(const CalendarDate(2026, 10, 29));
      addEntry(1200, const CalendarDate(2026, 10, 29), recurringId: WorkedExample.electricity.id);
      recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        WorkedExample.rent,
        RecurringRule(
          id: WorkedExample.electricity.id,
          label: WorkedExample.electricity.label,
          amount: WorkedExample.electricity.amount,
          kind: WorkedExample.electricity.kind,
          categoryId: WorkedExample.electricity.categoryId,
          schedule: WorkedExample.electricity.schedule,
          nextDue: const CalendarDate(2026, 11, 29),
        ),
      ];
      expect(
        (await summary()).savedYesterday,
        Option<YesterdaySaving>.of(YesterdaySaving(saved: Money.fromMajor(2318), eachDayMore: Money.fromMajor(386))),
      );
    });

    test('overspending yesterday shows no note', () async {
      addEntry(2000, const CalendarDate(2026, 10, 25));
      expect((await summary()).savedYesterday, const Option<YesterdaySaving>.none());
    });

    // A mid-cycle install: onboarding back-posts salary to 4 Oct, but every entry is saved at [at].
    void allSavedAt(DateTime at) => ledger.entries.replaceRange(0, ledger.entries.length, <Entry>[
          for (final Entry e in WorkedExample.entries)
            Entry(
              id: e.id,
              amount: e.amount,
              kind: e.kind,
              categoryId: e.categoryId,
              date: e.date,
              createdAt: at,
              recurringId: e.recurringId,
            ),
        ]);

    test('first used today: yesterday wasn\'t tracked, so no note', () async {
      allSavedAt(WorkedExample.now);
      expect((await summary()).savedYesterday, const Option<YesterdaySaving>.none());
    });

    test('first used late yesterday: the note shows', () async {
      allSavedAt(DateTime(2026, 10, 25, 23, 50));
      expect((await summary()).savedYesterday.isSome(), isTrue);
    });

    test('on payday yesterday was the last cycle, so no note', () async {
      setToday(const CalendarDate(2026, 10, 4));
      expect((await summary()).savedYesterday, const Option<YesterdaySaving>.none());
    });
  });

  group('GetCycleSummary — a changed payday (BR-1a, D140)', () {
    CycleSummary right(Either<Failure, CycleSummary> result) => result.getOrElse((Failure f) => fail('unexpected $f'));

    test('preview: payday to the 25th bridges to 24 Nov, and rent on 5 Nov comes out of it', () async {
      final CycleSummary summary = right(await getCycleSummary.preview(const MonthlyOnDay(25)).run());
      expect(summary.cycle, const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 24)));
      expect(summary.todayShare, Money.fromMajor(281));
    });

    test('preview: payday to the 1st ends this cycle on 31 Oct', () async {
      final CycleSummary summary = right(await getCycleSummary.preview(const MonthlyOnDay(1)).run());
      expect(summary.cycle.end, const CalendarDate(2026, 10, 31));
      expect(summary.todayShare, Money.fromMajor(2775));
    });

    test('preview: the same rule changes nothing', () async {
      final CycleSummary now = right(await getCycleSummary(const NoParams()).run());
      expect(right(await getCycleSummary.preview(const MonthlyOnDay(4)).run()), now);
    });

    test('a stored switch shapes today\'s cycle', () async {
      settings.settings = const BudgetSettings(
        paySwitches: <PaySwitch>[PaySwitch(on: CalendarDate(2026, 10, 26), from: MonthlyOnDay(25))],
      );
      final CycleSummary summary = right(await getCycleSummary(const NoParams()).run());
      expect(summary.cycle, const PayCycle(start: CalendarDate(2026, 10, 25), end: CalendarDate(2026, 11, 3)));
    });

    test('preview passes a settings failure through', () async {
      settings.failure = DatabaseFailure('boom');
      expect((await getCycleSummary.preview(const MonthlyOnDay(1)).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
