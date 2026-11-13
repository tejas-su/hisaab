import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/core/time/pay_switch.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/data/datasource/budget_settings_local_data_source.dart';
import 'package:hisaab/ledger/data/datasource/entries_local_data_source.dart';
import 'package:hisaab/ledger/data/datasource/recurring_local_data_source.dart';
import 'package:hisaab/ledger/data/repository/budget_settings_repository_impl.dart';
import 'package:hisaab/ledger/data/repository/ledger_repository_impl.dart';
import 'package:hisaab/ledger/data/repository/recurring_repository_impl.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/shortcuts/domain/entities/projected_day.dart';
import 'package:hisaab/shortcuts/domain/usecase/project_widget_days.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/test_database.dart';

/// The real ledger on a real (in-memory) database, as the app wires it.
final class _RealLedger {
  _RealLedger(AppDatabase database, this.clock)
      : ledger = LedgerRepositoryImpl(entries: SqfliteEntriesLocalDataSource(database), clock: clock),
        recurring = RecurringRepositoryImpl(recurring: SqfliteRecurringLocalDataSource(database), clock: clock),
        settings = BudgetSettingsRepositoryImpl(settings: SqfliteBudgetSettingsLocalDataSource(database));

  final FakeClock clock;
  final LedgerRepositoryImpl ledger;
  final RecurringRepositoryImpl recurring;
  final BudgetSettingsRepositoryImpl settings;

  Future<void> rule(String label, int rupees, EntryKind kind, Schedule schedule,
      {bool income = false, AmountMode mode = AmountMode.fixed, int category = SeedCategoryIds.bills}) async {
    _right(
      await recurring
          .add(RecurringDraft(
            label: label,
            amount: Money.fromMajor(rupees),
            kind: kind,
            categoryId: category,
            schedule: schedule,
            nextDue: schedule.anchor,
            isIncomeSource: income,
            amountMode: mode,
          ))
          .run(),
    );
  }

  Future<void> spend(int rupees, CalendarDate date) async => _right(
        await ledger
            .add(EntryDraft(amount: Money.fromMajor(rupees), kind: EntryKind.spent, categoryId: SeedCategoryIds.food, date: date))
            .run(),
      );

  ProjectWidgetDays get projector => ProjectWidgetDays(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: clock,
      );

  /// Opens the "app" on [day]: the engine runs, then Home's summary is read, as HomeBloc does.
  Future<ProjectedDay> openOn(CalendarDate day) async {
    clock.current = DateTime(day.year, day.month, day.day, 9);
    _right(await PostDueRecurring(recurring: recurring, clock: clock).call(const NoParams()).run());
    final CycleSummary summary = _right(
      await GetCycleSummary(ledger: ledger, recurring: recurring, settings: settings, periods: const PeriodCalculator(), clock: clock)
          .call(const NoParams())
          .run(),
    );
    final List<Entry> today = _right(await ledger.entriesBetween(day, day).run());
    return ProjectedDay(
      summary: summary,
      spends: today.reversed.where((Entry e) => e.kind == EntryKind.spent && e.recurringId == null).toList(),
    );
  }
}

T _right<T>(Either<Failure, T> result) => result.getOrElse((Failure f) => fail(f.message));

Schedule _monthly(CalendarDate anchor) => Schedule(frequency: Frequency.monthly, anchor: anchor);

/// The oracle (widget spec §5): every projected day equals what the real engine and summary give
/// when the app is opened on that day, with nothing new typed.
Future<List<ProjectedDay>> _expectParity(_RealLedger real) async {
  final List<ProjectedDay> projected = _right(await real.projector.call(const NoParams()).run());
  for (final ProjectedDay day in projected) {
    final ProjectedDay actual = await real.openOn(day.summary.today);
    expect(day, actual, reason: 'day ${day.summary.today}');
  }
  return projected;
}

void main() {
  group('ProjectWidgetDays (oracle against the real engine and summary)', () {
    late _RealLedger real;

    setUp(() async {
      final AppDatabase database = await openTestDatabase();
      real = _RealLedger(database, FakeClock(DateTime(2026, 10, 26, 21)));
    });

    test('a fixed, a changing and a card bill, a saving and payday on the 4th', () async {
      await real.rule('Salary', 45000, EntryKind.got, _monthly(const CalendarDate(2026, 10, 4)), income: true, category: SeedCategoryIds.salary);
      await real.rule('Rent', 8200, EntryKind.spent, _monthly(const CalendarDate(2026, 10, 5)), category: SeedCategoryIds.home);
      await real.rule('Electricity', 1200, EntryKind.spent, _monthly(const CalendarDate(2026, 10, 29)), mode: AmountMode.varies);
      await real.rule('Card', 9000, EntryKind.spent, _monthly(const CalendarDate(2026, 10, 30)), mode: AmountMode.card);
      await real.rule('RD', 5000, EntryKind.saved, _monthly(const CalendarDate(2026, 10, 10)), category: SeedCategoryIds.saved);
      await real.spend(18950, const CalendarDate(2026, 10, 20));
      await real.spend(40, const CalendarDate(2026, 10, 26));
      await real.spend(380, const CalendarDate(2026, 10, 26));

      final List<ProjectedDay> days = await _expectParity(real);

      expect(days.first.summary.today, const CalendarDate(2026, 10, 26));
      expect(days.first.spends.map((Entry e) => e.amount), <Money>[Money.fromMajor(40), Money.fromMajor(380)]);
      // why: today's cycle runs to 3 Nov; the next one, from payday on 4 Nov, ends on 3 Dec.
      expect(days.last.summary.today, const CalendarDate(2026, 12, 3));
      expect(days.skip(1).every((ProjectedDay d) => d.spends.isEmpty), isTrue);
    });

    test('payday on the 31st across February in a leap year', () async {
      real.clock.current = DateTime(2028, 2, 10, 8);
      await real.rule('Salary', 60000, EntryKind.got, _monthly(const CalendarDate(2028, 1, 31)), income: true, category: SeedCategoryIds.salary);
      await real.rule('Rent', 15000, EntryKind.spent, _monthly(const CalendarDate(2028, 2, 1)), category: SeedCategoryIds.home);
      await real.spend(200, const CalendarDate(2028, 2, 10));

      final List<ProjectedDay> days = await _expectParity(real);

      expect(days.map((ProjectedDay d) => d.summary.today), contains(const CalendarDate(2028, 2, 29)));
      expect(days.last.summary.today.month, 3);
    });

    test('a cycle crossing the year end', () async {
      real.clock.current = DateTime(2026, 12, 20, 8);
      await real.rule('Salary', 40000, EntryKind.got, _monthly(const CalendarDate(2026, 12, 15)), income: true, category: SeedCategoryIds.salary);

      final List<ProjectedDay> days = await _expectParity(real);

      expect(days.last.summary.today, const CalendarDate(2027, 2, 14));
    });

    test('over today, then over for the whole cycle', () async {
      await real.rule('Salary', 20000, EntryKind.got, _monthly(const CalendarDate(2026, 10, 4)), income: true, category: SeedCategoryIds.salary);
      await real.spend(19000, const CalendarDate(2026, 10, 25));
      await real.spend(3000, const CalendarDate(2026, 10, 26));

      final List<ProjectedDay> days = await _expectParity(real);

      expect(days.first.summary.state, isA<OverCycle>());
      expect(days.where((ProjectedDay d) => d.summary.cycle.start == const CalendarDate(2026, 11, 4)).first.summary.state, isA<OnTrack>());
    });

    test('over today only', () async {
      await real.rule('Salary', 45000, EntryKind.got, _monthly(const CalendarDate(2026, 10, 4)), income: true, category: SeedCategoryIds.salary);
      await real.spend(8000, const CalendarDate(2026, 10, 26));

      final List<ProjectedDay> days = await _expectParity(real);

      expect(days.first.summary.state, isA<OverToday>());
    });

    test('a pay switch from the 4th to the last day of the month (D140)', () async {
      await real.rule('Salary', 45000, EntryKind.got, Schedule(frequency: Frequency.monthly, anchor: const CalendarDate(2026, 10, 31), lastDayOfMonth: true),
          income: true, category: SeedCategoryIds.salary);
      _right(await real.settings.addPaySwitch(const PaySwitch(on: CalendarDate(2026, 10, 20), from: MonthlyOnDay(4))).run());

      await _expectParity(real);
    });

    test('weekly pay ends the window a week after this one', () async {
      await real.rule('Wages', 6000, EntryKind.got, Schedule(frequency: Frequency.weekly, anchor: const CalendarDate(2026, 10, 23)),
          income: true, category: SeedCategoryIds.salary);

      final List<ProjectedDay> days = await _expectParity(real);

      expect(days, hasLength(lessThanOrEqualTo(14)));
    });

    test('no income at all gives a no-income day for each date', () async {
      final List<ProjectedDay> days = await _expectParity(real);

      expect(days, isNotEmpty);
      expect(days.every((ProjectedDay d) => d.summary.state is NoIncome), isTrue);
    });
  });

  group('ProjectWidgetDays (reads)', () {
    test('returns the first read failure and writes nothing', () async {
      final FakeLedgerRepository ledger = FakeLedgerRepository(WorkedExample.entries)..failure = DatabaseFailure('locked');
      addTearDown(ledger.dispose);
      final FakeRecurringRepository recurring = FakeRecurringRepository(WorkedExample.rules);
      final ProjectWidgetDays projector = ProjectWidgetDays(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: FakeClock(WorkedExample.now),
      );

      final Either<Failure, List<ProjectedDay>> result = await projector.call(const NoParams()).run();

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
      expect(recurring.rules.map((RecurringRule r) => r.nextDue), WorkedExample.rules.map((RecurringRule r) => r.nextDue));
    });
  });
  group('ProjectWidgetDays with a Used entry (FR-WG-5, BR-19, U7)', () {
    test('the snapshot after a used entry has the same hero for today and every later day', () async {
      final AppDatabase database = await openTestDatabase();
      final _RealLedger real = _RealLedger(database, FakeClock(DateTime(2026, 10, 26, 21)));
      await real.rule('Salary', 45000, EntryKind.got, _monthly(const CalendarDate(2026, 10, 4)), income: true, category: SeedCategoryIds.salary);
      await real.rule('Rent', 8200, EntryKind.spent, _monthly(const CalendarDate(2026, 10, 5)), category: SeedCategoryIds.home);
      await real.rule('Insurance', 1000, EntryKind.saved, _monthly(const CalendarDate(2026, 10, 5)), category: SeedCategoryIds.saved);
      await real.spend(420, const CalendarDate(2026, 10, 26));
      final List<ProjectedDay> before = _right(await real.projector.call(const NoParams()).run());

      _right(
        await real.ledger
            .addForSaving(
              EntryDraft(
                amount: Money.fromMajor(12000),
                kind: EntryKind.used,
                categoryId: SeedCategoryIds.saved,
                date: const CalendarDate(2026, 10, 26),
                note: 'Insurance',
              ),
              savingId: 1,
            )
            .run(),
      );
      final List<ProjectedDay> after = _right(await real.projector.call(const NoParams()).run());

      expect(after, before);
      expect(after.first.summary.safeToday, before.first.summary.safeToday);
      // why: checking against the real engine posts the bills of every day, so it runs last.
      await _expectParity(real);
    });
  });

}
