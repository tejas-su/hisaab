import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/data/datasource/recurring_local_data_source.dart';
import 'package:expense_tracker/ledger/data/repository/recurring_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/ledger_setup.dart';
import 'package:expense_tracker/ledger/domain/entities/occurrence.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_posting.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:expense_tracker/ledger/domain/usecase/post_due_recurring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/test_database.dart';

final RecurringDraft _salary = RecurringDraft(
  label: 'Salary',
  amount: Money.fromMajor(45000),
  kind: EntryKind.got,
  categoryId: SeedCategoryIds.salary,
  schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 4)),
  nextDue: const CalendarDate(2026, 10, 4),
  isIncomeSource: true,
);

final RecurringDraft _milk = RecurringDraft(
  label: 'Milk',
  amount: Money.fromMajor(300),
  kind: EntryKind.spent,
  categoryId: SeedCategoryIds.food,
  schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 9, 18)),
  nextDue: const CalendarDate(2026, 9, 18),
);

void main() {
  late AppDatabase database;
  late RecurringRepositoryImpl repository;
  late FakeClock clock;

  setUp(() async {
    database = await openTestDatabase();
    clock = FakeClock(DateTime(2026, 10, 26, 9));
    repository = RecurringRepositoryImpl(recurring: SqfliteRecurringLocalDataSource(database), clock: clock);
  });

  T right<T>(Either<Failure, T> result) => result.getOrElse((Failure f) => fail(f.message));
  Future<List<Map<String, Object?>>> entries() => database.db.query(Tables.transactions, orderBy: TransactionColumns.date);
  PostDueRecurring engine() => PostDueRecurring(recurring: repository, clock: clock);

  group('RecurringRepositoryImpl.startFresh', () {
    test('stores the rules and opening entries', () async {
      final EntryDraft opening = EntryDraft(
        amount: Money.fromMajor(30000),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.salary,
        date: const CalendarDate(2026, 10, 1),
      );
      right(await repository.startFresh(LedgerSetup(rules: <RecurringDraft>[_salary, _milk], entries: <EntryDraft>[opening])).run());
      final List<RecurringRule> rules = right(await repository.activeRules().run());
      expect(rules.map((RecurringRule r) => (r.label, r.isIncomeSource)), <(String, bool)>[('Salary', true), ('Milk', false)]);
      expect(await entries(), hasLength(1));
    });

    test('repeating it replaces everything instead of duplicating', () async {
      final LedgerSetup setup = LedgerSetup(rules: <RecurringDraft>[_salary]);
      right(await repository.startFresh(setup).run());
      right(await repository.startFresh(setup).run());
      expect(right(await repository.activeRules().run()), hasLength(1));
    });

    test('rolls back as a whole when a row is rejected', () async {
      right(await repository.startFresh(LedgerSetup(rules: <RecurringDraft>[_milk])).run());
      final RecurringDraft broken = RecurringDraft(
        label: 'Broken',
        amount: Money.zero,
        kind: EntryKind.spent,
        categoryId: 1,
        schedule: _milk.schedule,
        nextDue: _milk.nextDue,
      );
      final Either<Failure, Unit> result = await repository.startFresh(LedgerSetup(rules: <RecurringDraft>[_salary, broken])).run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
      expect(right(await repository.activeRules().run()).single.label, 'Milk');
    });
  });

  group('RecurringRepositoryImpl.post via PostDueRecurring (BR-9)', () {
    setUp(() async {
      right(await repository.startFresh(LedgerSetup(rules: <RecurringDraft>[_salary, _milk])).run());
    });

    test('E7: posts the salary and six weekly catch-ups, each dated on its due day', () async {
      expect(await engine()(const NoParams()).run(), Either<Failure, int>.right(7));
      final List<Map<String, Object?>> rows = await entries();
      expect(rows.map((Map<String, Object?> r) => r[TransactionColumns.date]).toList(), <String>[
        '2026-09-18', '2026-09-25', '2026-10-02', '2026-10-04', '2026-10-09', '2026-10-16', '2026-10-23', //
      ]);
      final List<RecurringRule> rules = right(await repository.activeRules().run());
      expect(rules.map((RecurringRule r) => r.nextDue), <CalendarDate>[const CalendarDate(2026, 11, 4), const CalendarDate(2026, 10, 30)]);
    });

    test('a second run the same day posts nothing (idempotent)', () async {
      right(await engine()(const NoParams()).run());
      expect(await engine()(const NoParams()).run(), Either<Failure, int>.right(0));
      expect(await entries(), hasLength(7));
    });

    test('E8: a racing run with stale next dates still never double-posts', () async {
      final List<RecurringRule> stale = right(await repository.activeRules().run());
      right(await engine()(const NoParams()).run());
      final RecurringPosting replay = RecurringPosting(
        occurrences: <Occurrence>[Occurrence(rule: stale.last, date: const CalendarDate(2026, 9, 18))],
        nextDueByRuleId: <int, CalendarDate>{stale.last.id: const CalendarDate(2026, 10, 30)},
      );
      expect(await repository.post(replay).run(), Either<Failure, int>.right(0));
      expect(await entries(), hasLength(7));
    });

    test('rejects an invalid occurrence before writing, since OR IGNORE would hide it', () async {
      final RecurringRule rule = right(await repository.activeRules().run()).last;
      final RecurringRule broken = RecurringRule(
        id: rule.id,
        label: rule.label,
        amount: Money.zero,
        kind: rule.kind,
        categoryId: rule.categoryId,
        schedule: rule.schedule,
        nextDue: rule.nextDue,
      );
      final RecurringPosting posting = RecurringPosting(
        occurrences: <Occurrence>[Occurrence(rule: broken, date: rule.nextDue)],
        nextDueByRuleId: <int, CalendarDate>{rule.id: const CalendarDate(2026, 10, 30)},
      );
      expect((await repository.post(posting).run()).getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(right(await repository.activeRules().run()).last.nextDue, rule.nextDue);
    });

    test('returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.activeRules().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
