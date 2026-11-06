import 'package:expense_tracker/core/db/app_database.dart';
import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/data/datasource/recurring_local_data_source.dart';
import 'package:expense_tracker/ledger/data/repository/recurring_repository_impl.dart';
import 'package:expense_tracker/ledger/domain/entities/amount_mode.dart';
import 'package:expense_tracker/ledger/domain/entities/bill_icon.dart';
import 'package:expense_tracker/ledger/domain/entities/bill_skip.dart';
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

    test('clears earlier pay switches (D140)', () async {
      await database.db.insert(Tables.settings, <String, Object?>{SettingsColumns.key: SettingKeys.paySwitches, SettingsColumns.value: '[]'});
      right(await repository.startFresh(LedgerSetup(rules: <RecurringDraft>[_salary])).run());
      expect(await database.db.query(Tables.settings, where: '${SettingsColumns.key} = ?', whereArgs: <Object?>[SettingKeys.paySwitches]), isEmpty);
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

    test('a save rule posts a Saved entry named after it (D120)', () async {
      final RecurringRule rd = right(await repository.add(RecurringDraft(
        label: 'RD',
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 10)),
        nextDue: const CalendarDate(2026, 10, 10),
      )).run());
      right(await repository.post(RecurringPosting(
        occurrences: <Occurrence>[Occurrence(rule: rd, date: const CalendarDate(2026, 10, 10))],
        nextDueByRuleId: <int, CalendarDate>{rd.id: const CalendarDate(2026, 11, 10)},
      )).run());
      final Map<String, Object?> row = (await database.db.query(Tables.transactions, where: "${TransactionColumns.kind} = 'save'")).single;
      expect(row[TransactionColumns.note], 'RD');
      expect(row[TransactionColumns.recurringId], rd.id);
    });

    test('returns DatabaseFailure when the database is closed', () async {
      await database.close();
      expect((await repository.activeRules().run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('RecurringRepositoryImpl skips (D123)', () {
    late RecurringRule electricity;
    late List<void> changes;
    const CalendarDate oct20 = CalendarDate(2026, 10, 20);

    setUp(() async {
      electricity = right(await repository.add(RecurringDraft(
        label: 'Electricity',
        amount: Money.fromMajor(1200),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: oct20),
        nextDue: oct20,
        amountMode: AmountMode.varies,
      )).run());
      changes = <void>[];
      repository.changes.listen(changes.add);
      addTearDown(repository.dispose);
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('the amount mode is stored and read back', () async {
      expect(right(await repository.activeRules().run()).single.amountMode, AmountMode.varies);
    });

    test('skip is listed by skipsBetween, notifies, and unskip removes it', () async {
      final BillSkip skip = BillSkip(ruleId: electricity.id, date: oct20);
      right(await repository.skip(skip).run());
      await settle();
      expect(right(await repository.skipsBetween(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 10, 26)).run()), <BillSkip>[skip]);
      expect(changes, hasLength(1));
      right(await repository.unskip(skip).run());
      await settle();
      expect(right(await repository.skipsBetween(const CalendarDate(2026, 10, 4), const CalendarDate(2026, 10, 26)).run()), isEmpty);
      expect(changes, hasLength(2));
    });

    test('skipsBetween leaves out dates outside the range', () async {
      right(await repository.skip(BillSkip(ruleId: electricity.id, date: oct20)).run());
      expect(right(await repository.skipsBetween(const CalendarDate(2026, 10, 21), const CalendarDate(2026, 11, 3)).run()), isEmpty);
    });

    test('skipping twice keeps one row', () async {
      final BillSkip skip = BillSkip(ruleId: electricity.id, date: oct20);
      right(await repository.skip(skip).run());
      right(await repository.skip(skip).run());
      expect(await database.db.query(Tables.recurringSkips), hasLength(1));
    });

    test('post leaves out an occurrence that was skipped (E-f)', () async {
      right(await repository.skip(BillSkip(ruleId: electricity.id, date: oct20)).run());
      final int posted = right(await repository.post(RecurringPosting(
        occurrences: <Occurrence>[Occurrence(rule: electricity, date: oct20)],
        nextDueByRuleId: <int, CalendarDate>{electricity.id: const CalendarDate(2026, 11, 20)},
      )).run());
      expect(posted, 0);
      expect(await entries(), isEmpty);
    });
  });

  group('RecurringRepositoryImpl bill writes (FR-SE-1)', () {
    late List<void> changes;

    setUp(() async {
      right(await repository.startFresh(LedgerSetup(rules: <RecurringDraft>[_salary])).run());
      changes = <void>[];
      repository.changes.listen(changes.add);
      addTearDown(repository.dispose);
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('add stores an active rule, returns it with its id and notifies', () async {
      final RecurringRule added = right(await repository.add(_milk).run());
      await settle();
      expect(added, right(await repository.activeRules().run()).last);
      expect(added.draft, _milk);
      expect(changes, hasLength(1));
    });

    test('update overwrites an active rule\'s fields, keeps its id and notifies', () async {
      final RecurringRule added = right(await repository.add(_milk).run());
      final RecurringRule edited = RecurringRule(
        id: added.id,
        label: 'Milk & bread',
        amount: Money.fromMajor(350),
        kind: added.kind,
        categoryId: added.categoryId,
        schedule: added.schedule,
        nextDue: const CalendarDate(2026, 10, 30),
      );
      expect(right(await repository.update(edited).run()), edited);
      await settle();
      expect(right(await repository.activeRules().run()).last, edited);
      expect(changes, hasLength(2));
    });

    test('add and update keep a picked bill icon, and none clears it (D118)', () async {
      final RecurringDraft gas = RecurringDraft(
        label: 'Gas',
        amount: Money.fromMajor(900),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: _milk.schedule,
        nextDue: _milk.nextDue,
        icon: const Option<BillIcon>.of(BillIcon.gas),
      );
      final RecurringRule added = right(await repository.add(gas).run());
      expect(added.icon, const Option<BillIcon>.of(BillIcon.gas));
      expect(right(await repository.activeRules().run()).last.icon, const Option<BillIcon>.of(BillIcon.gas));

      right(await repository.update(added.copyWith(icon: const Option<BillIcon>.none())).run());
      expect(right(await repository.activeRules().run()).last.icon, const Option<BillIcon>.none());
    });

    test('update returns RuleNotFoundFailure for a missing rule and doesn\'t notify', () async {
      final RecurringRule ghost = RecurringRule(
        id: 99,
        label: 'Ghost',
        amount: Money.fromMajor(1),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: _milk.schedule,
        nextDue: _milk.nextDue,
      );
      expect((await repository.update(ghost).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
      await settle();
      expect(changes, isEmpty);
    });

    test('setActive(false) stops a rule and keeps its posted entries; true brings it back', () async {
      final RecurringRule added = right(await repository.add(_milk).run());
      right(await engine()(const NoParams()).run());
      final int posted = (await entries()).length;

      right(await repository.setActive(added.id, active: false).run());
      expect(right(await repository.activeRules().run()).map((RecurringRule r) => r.id), isNot(contains(added.id)));
      expect(await entries(), hasLength(posted));

      right(await repository.setActive(added.id, active: true).run());
      expect(right(await repository.activeRules().run()).last, added.copyWith(nextDue: const CalendarDate(2026, 10, 30)));
      await settle();
      expect(changes, hasLength(3));
    });

    test('an inactive rule can\'t be updated', () async {
      final RecurringRule added = right(await repository.add(_milk).run());
      right(await repository.setActive(added.id, active: false).run());
      expect((await repository.update(added).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });

    test('setActive returns RuleNotFoundFailure for a missing rule', () async {
      expect((await repository.setActive(99, active: false).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });

    test('add returns DatabaseFailure when a CHECK rejects the row', () async {
      final RecurringDraft zero = RecurringDraft(
        label: 'Zero',
        amount: Money.zero,
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: _milk.schedule,
        nextDue: _milk.nextDue,
      );
      expect((await repository.add(zero).run()).getLeft().toNullable(), isA<DatabaseFailure>());
      await settle();
      expect(changes, isEmpty);
    });
  });
}
