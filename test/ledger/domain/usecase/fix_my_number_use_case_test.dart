import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/domain/entities/cycle_summary.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:hisaab/ledger/domain/fix_my_number.dart';
import 'package:hisaab/ledger/domain/usecase/delete_entry.dart';
import 'package:hisaab/ledger/domain/usecase/fix_my_number_use_case.dart';
import 'package:hisaab/ledger/domain/usecase/get_cycle_summary.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// BR-18 *Posting* and *Stale write* against the worked example (H 17,430).
void main() {
  late FakeLedgerRepository ledger;
  late FakeBudgetSettingsRepository settings;
  late FakeClock clock;
  late GetCycleSummary summaryOf;
  late FixMyNumberUseCase fix;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    settings = FakeBudgetSettingsRepository();
    clock = FakeClock(WorkedExample.now);
    summaryOf = GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules]),
      settings: settings,
      periods: const PeriodCalculator(),
      clock: clock,
    );
    fix = FixMyNumberUseCase(
      summary: summaryOf,
      ledger: ledger,
      categories: FakeCategoryRepository(),
      settings: settings,
      clock: clock,
    );
  });

  tearDown(() => ledger.dispose());

  Future<CycleSummary> summary() async =>
      (await summaryOf(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));

  /// The signed rupees the preview would have shown for [typed].
  Future<int> seenGap(int typed) async => FixMyNumber.signedRupees(await summary(), typed);

  Future<Either<Failure, Entry>> fixTo(int typed, {int? seen}) async =>
      fix(FixParams(typedRupees: typed, seenGapRupees: seen ?? await seenGap(typed))).run();

  Future<Entry> fixOk(int typed) async => (await fixTo(typed)).getOrElse((Failure f) => fail(f.message));

  group('FixMyNumberUseCase', () {
    test('case 1 writes Spent 4,200 in not logged, dated today, note "Not logged", no recurring id', () async {
      final Entry entry = await fixOk(13230);

      expect(
        (entry.amount, entry.kind, entry.categoryId, entry.date, entry.note, entry.recurringId, entry.savingId),
        (Money.fromMajor(4200), EntryKind.spent, SeedCategoryIds.notLogged, WorkedExample.today, 'Not logged', null, null),
      );
      expect(entry.isNotLogged, isTrue);
      expect((await summary()).safeToday, Money.fromMajor(963));
    });

    test('case 2 writes Got 1,000 in not logged (in)', () async {
      final Entry entry = await fixOk(18430);

      expect((entry.amount, entry.kind, entry.categoryId), (Money.fromMajor(1000), EntryKind.got, SeedCategoryIds.notLoggedIn));
      expect((await summary()).safeToday, Money.fromMajor(1541));
    });

    test('after the write H equals T to within ₹1', () async {
      await fixOk(13230);

      final Money held = FixMyNumber.held(await summary());
      expect((held - Money.fromMajor(13230)).amountMinor.abs() < 100, isTrue);
    });

    test('an ordinary midnight keeps the gap (H does not depend on the day), so the fix still saves', () async {
      final int seen = await seenGap(13230);
      clock.advance(const Duration(days: 1));

      final Entry entry = (await fixTo(13230, seen: seen)).getOrElse((Failure f) => fail(f.message));

      expect(entry.date, WorkedExample.today.addDays(1));
    });

    test('a midnight into a new cycle: the gap differs, nothing is saved, FixStaleFailure (E84)', () async {
      final int seen = await seenGap(13230);
      clock.current = DateTime(2026, 11, 4, 0, 5);

      final Either<Failure, Entry> result = await fixTo(13230, seen: seen);

      expect(result.getLeft().toNullable(), isA<FixStaleFailure>());
      expect(ledger.saved, isEmpty);
    });

    test('a bill posted while the sheet was open: stale, nothing saved', () async {
      final int seen = await seenGap(13230);
      ledger.entries.add(Entry(
        id: 700,
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));

      expect((await fixTo(13230, seen: seen)).getLeft().toNullable(), isA<FixStaleFailure>());
      expect(ledger.saved, isEmpty);
    });

    test('a drift under ₹1 behind the sheet does not refuse the save (D191)', () async {
      Entry paise(int id, int minor) => Entry(
            id: id,
            amount: Money(minor),
            kind: EntryKind.spent,
            categoryId: SeedCategoryIds.food,
            date: WorkedExample.today.addDays(-1),
            createdAt: WorkedExample.now,
          );
      ledger.entries.add(paise(710, 50));
      final int seen = await seenGap(13230);
      expect(seen, 4199);
      ledger.entries.add(paise(711, 25));

      final Entry entry = (await fixTo(13230, seen: seen)).getOrElse((Failure f) => fail(f.message));

      expect(entry.amount, Money.fromMajor(4199));
    });

    test('a drift that moves the rupees to post is stale, in either direction', () async {
      final int seen = await seenGap(13230);
      ledger.entries.add(Entry(
        id: 712,
        amount: Money.fromMajor(1),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.salary,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));

      expect((await fixTo(13230, seen: seen)).getLeft().toNullable(), isA<FixStaleFailure>());
    });

    test('equal and close write nothing', () async {
      expect((await fixTo(17430)).getLeft().toNullable(), isA<FixNothingToFixFailure>());
      expect((await fixTo(17400)).getLeft().toNullable(), isA<FixNothingToFixFailure>());
      expect(ledger.saved, isEmpty);
    });

    test('a second Fix it right after the first writes nothing', () async {
      final int seen = await seenGap(13230);
      await fixOk(13230);

      final Either<Failure, Entry> second = await fixTo(13230, seen: seen);

      expect(second.isLeft(), isTrue);
      expect(ledger.saved, hasLength(1));
    });

    test('a second fix on the same figure, seen as equal, says there is nothing to fix', () async {
      await fixOk(13230);

      expect((await fixTo(13230)).getLeft().toNullable(), isA<FixNothingToFixFailure>());
    });

    test('the write is dated today even on the cycle first day', () async {
      clock.current = DateTime(2026, 10, 4, 9);

      final Entry entry = (await fix(FixParams(typedRupees: 1000, seenGapRupees: await seenGap(1000))).run())
          .getOrElse((Failure f) => fail(f.message));

      expect(entry.date, const CalendarDate(2026, 10, 4));
    });

    test('a failure reading or writing is passed through and nothing is half-written', () async {
      final int seen = await seenGap(13230);
      ledger.failure = DatabaseFailure('down');

      final Either<Failure, Entry> result = await fixTo(13230, seen: seen);

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
      expect(ledger.saved, isEmpty);
      expect(settings.installSeen, isFalse);
    });

    test('a successful write sets install_line_seen; a failed flag write does not fail the fix', () async {
      settings.seenFailure = DatabaseFailure('flag');

      final Entry entry = await fixOk(13230);

      expect(entry.isNotLogged, isTrue);
      expect(settings.installSeen, isFalse);
      settings.seenFailure = null;
      await fixOk(14230);
      expect(settings.installSeen, isTrue);
    });

    test('Undo (DeleteEntry) does not clear the flag', () async {
      final Entry entry = await fixOk(13230);

      await DeleteEntry(ledger: ledger)(entry.id).run();

      expect(settings.installSeen, isTrue);
    });

    test('a Got fix over the 9-digit cap is refused by the validator', () async {
      ledger.entries.add(Entry(
        id: 701,
        amount: Money.fromMajor(100000000000),
        kind: EntryKind.got,
        categoryId: SeedCategoryIds.salary,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));

      final Either<Failure, Entry> result = await fixTo(1);

      expect(result.getLeft().toNullable(), isA<InvalidAmountFailure>());
    });
  });
}
