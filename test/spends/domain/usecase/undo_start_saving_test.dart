import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/data/datasource/budget_settings_local_data_source.dart';
import 'package:hisaab/ledger/data/datasource/categories_local_data_source.dart';
import 'package:hisaab/ledger/data/datasource/entries_local_data_source.dart';
import 'package:hisaab/ledger/data/datasource/recurring_local_data_source.dart';
import 'package:hisaab/ledger/data/repository/budget_settings_repository_impl.dart';
import 'package:hisaab/ledger/data/repository/category_repository_impl.dart';
import 'package:hisaab/ledger/data/repository/ledger_repository_impl.dart';
import 'package:hisaab/ledger/data/repository/recurring_repository_impl.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/saving_started.dart';
import 'package:hisaab/spends/domain/usecase/start_saving_for.dart';
import 'package:hisaab/spends/domain/usecase/undo_start_saving.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/spends/afford_book.dart';
import '../../../helpers/test_database.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late UndoStartSaving undo;

  final RecurringRule before = AffordBook.mac(target: Option<Money>.of(Money.fromMajor(90000)));
  final RecurringRule after = before.copyWith(amount: Money.fromMajor(8000), target: Option<Money>.of(Money.fromMajor(67000)));

  setUp(() {
    ledger = FakeLedgerRepository();
    recurring = FakeRecurringRepository(<RecurringRule>[...AffordBook.rules(), after], ledger);
    undo = UndoStartSaving(recurring: recurring);
  });

  group('UndoStartSaving (E164)', () {
    test('a new saving is deleted', () async {
      final Either<Failure, Unit> result = await undo(SavingStarted(rule: after, previous: const Option<RecurringRule>.none())).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(recurring.rules.where((RecurringRule r) => r.id == AffordBook.macId), isEmpty);
      expect(recurring.stopped.single.id, AffordBook.macId);
    });

    test('a re-checked saving gets its old amount and target back, nothing else', () async {
      final Either<Failure, Unit> result = await undo(SavingStarted(rule: after, previous: Option<RecurringRule>.of(before))).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId), before);
    });

    test('a failed write is returned as Left', () async {
      recurring.failure = DatabaseFailure('x');

      final Either<Failure, Unit> result = await undo(SavingStarted(rule: after, previous: Option<RecurringRule>.of(before))).run();

      expect(result.isLeft(), isTrue);
    });

    test('outcomes compare by value', () {
      expect(
        SavingStarted(rule: after, previous: const Option<RecurringRule>.none()),
        SavingStarted(rule: after, previous: const Option<RecurringRule>.none()),
      );
    });
  });

  group('UndoStartSaving, a new saving whose put-in was already posted (E164)', () {
    final CalendarDate today = CalendarDate.fromDateTime(AffordBook.now);
    final RecurringRule fresh = after.copyWith(nextDue: today);

    Entry putIn(int id, int ruleId, CalendarDate date) => Entry(
      id: id,
      amount: Money.fromMajor(8000),
      kind: EntryKind.saved,
      categoryId: SeedCategoryIds.saved,
      date: date,
      createdAt: AffordBook.now,
      recurringId: ruleId,
    );

    test("deletes the saving's put-ins, then the saving, and keeps every other entry", () async {
      ledger.entries.addAll(<Entry>[putIn(1, AffordBook.macId, today), putIn(2, 99, today), putIn(3, AffordBook.macId, today.addDays(-31))]);

      final Either<Failure, Unit> result = await undo(SavingStarted(rule: fresh, previous: const Option<RecurringRule>.none())).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(ledger.entries.map((Entry e) => e.id), <int>[2, 3]);
      expect(recurring.stopped.single.id, AffordBook.macId);
    });

    test('a failed delete is Left and the saving keeps going, with no half-undo', () async {
      ledger.entries.add(putIn(1, AffordBook.macId, today));
      ledger.failure = DatabaseFailure('x');

      final Either<Failure, Unit> result = await undo(SavingStarted(rule: fresh, previous: const Option<RecurringRule>.none())).run();

      expect(result, Either<Failure, Unit>.left(DatabaseFailure('x')));
      expect(recurring.stopped, isEmpty);
    });
  });

  group('UndoStartSaving, a re-checked saving read fresh (D221)', () {
    test("puts back only the amount and target, keeping what the engine moved since", () async {
      final RecurringRule moved = after.copyWith(nextDue: after.nextDue.addDays(30));
      recurring.rules = <RecurringRule>[...AffordBook.rules(), moved];

      final Either<Failure, Unit> result = await undo(SavingStarted(rule: after, previous: Option<RecurringRule>.of(before))).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId), before.copyWith(nextDue: moved.nextDue));
    });

    test('a saving that is gone is RuleNotFoundFailure', () async {
      recurring.rules = AffordBook.rules();

      final Either<Failure, Unit> result = await undo(SavingStarted(rule: after, previous: Option<RecurringRule>.of(before))).run();

      expect(result.getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });
  });

  group('UndoStartSaving on the real ledger, the day after payday (E164 regression)', () {
    late FakeClock clock;
    late LedgerRepositoryImpl realLedger;
    late RecurringRepositoryImpl realRecurring;
    late BudgetSettingsRepositoryImpl settings;
    late CategoryRepositoryImpl categories;

    setUp(() async {
      final AppDatabase database = await openTestDatabase();
      // why: payday is the 4th, so on the 5th a new saving's first put-in (the day after payday) is today.
      clock = FakeClock(DateTime(2026, 11, 5, 9));
      realLedger = LedgerRepositoryImpl(entries: SqfliteEntriesLocalDataSource(database), clock: clock);
      realRecurring = RecurringRepositoryImpl(recurring: SqfliteRecurringLocalDataSource(database), clock: clock);
      settings = BudgetSettingsRepositoryImpl(settings: SqfliteBudgetSettingsLocalDataSource(database));
      categories = CategoryRepositoryImpl(categories: SqfliteCategoriesLocalDataSource(database));
    });

    T right<T>(Either<Failure, T> result) => result.getOrElse((Failure f) => fail(f.message));

    Future<void> runEngine() async => right(await PostDueRecurring(recurring: realRecurring, ledger: realLedger, clock: clock).call(const NoParams()).run());

    Future<CycleSummary> summary() async => right(
      await GetCycleSummary(
        ledger: realLedger,
        recurring: realRecurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: clock,
      ).call(const NoParams()).run(),
    );

    test("start saving, the engine posts today's put-in, Undo: no put-in remains and today's share is back", () async {
      const Schedule payday = Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 4));
      right(
        await realRecurring
            .add(
              RecurringDraft(
                label: 'Salary',
                amount: Money.fromMajor(45000),
                kind: EntryKind.got,
                categoryId: SeedCategoryIds.salary,
                schedule: payday,
                nextDue: payday.anchor,
                isIncomeSource: true,
              ),
            )
            .run(),
      );
      await runEngine();
      final CycleSummary beforeStart = await summary();

      final RecurringRule saving = right(
        await StartSavingFor(
              addBill: AddBill(recurring: realRecurring, categories: categories, clock: clock),
              editBill: EditBill(recurring: realRecurring, categories: categories, clock: clock),
              recurring: realRecurring,
            )(
              StartSavingParams(
                name: 'Mac',
                monthly: Money.fromMajor(5000),
                target: Money.fromMajor(67000),
                nextCycle: const PayCycle(start: CalendarDate(2026, 12, 4), end: CalendarDate(2027, 1, 3)),
                existing: const Option<RecurringRule>.none(),
              ),
            )
            .run(),
      );
      await runEngine();
      final List<Entry> posted = right(await realLedger.entriesBetween(clock.today(), clock.today()).run());
      expect(posted.where((Entry e) => e.recurringId == saving.id), hasLength(1), reason: 'the engine posts the put-in today');
      expect((await summary()).todayShare, isNot(beforeStart.todayShare));

      final UndoStartSaving realUndo = UndoStartSaving(recurring: realRecurring);
      right(await realUndo(SavingStarted(rule: saving, previous: const Option<RecurringRule>.none())).run());
      await runEngine();

      final List<Entry> left = right(await realLedger.entriesBetween(const CalendarDate(2026, 10, 1), clock.today()).run());
      expect(left.where((Entry e) => e.recurringId == saving.id), isEmpty);
      expect((await summary()).todayShare, beforeStart.todayShare);
    });
  });
}
