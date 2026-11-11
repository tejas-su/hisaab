import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/usecase/get_suggested_limits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

// The worked example's cycle is 4 Oct – 3 Nov 2026, so the previous one is 4 Sep – 3 Oct.
const CalendarDate _previousStart = CalendarDate(2026, 9, 4);

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBudgetSettingsRepository settings;
  late FakeCategoryRepository categories;

  void addEntry(int rupees, int categoryId, CalendarDate date, {EntryKind kind = EntryKind.spent, CalendarDate? loggedOn}) {
    final CalendarDate logged = loggedOn ?? date;
    ledger.entries.add(
      Entry(
        id: 100 + ledger.entries.length,
        amount: Money.fromMajor(rupees),
        kind: kind,
        categoryId: categoryId,
        date: date,
        createdAt: DateTime(logged.year, logged.month, logged.day, 9),
      ),
    );
  }

  // A full September: the app was first used on payday, 4 Sep.
  void useAppAllOfSeptember() {
    addEntry(45000, SeedCategoryIds.salary, _previousStart, kind: EntryKind.got);
    addEntry(8200, SeedCategoryIds.home, const CalendarDate(2026, 9, 5));
    addEntry(6000, SeedCategoryIds.food, const CalendarDate(2026, 9, 12));
    addEntry(3840, SeedCategoryIds.food, const CalendarDate(2026, 10, 3));
  }

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    settings = FakeBudgetSettingsRepository();
    categories = FakeCategoryRepository();
  });

  tearDown(() => ledger.dispose());

  Future<Either<Failure, Option<Map<int, Money>>>> suggest() => GetSuggestedLimits(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        categories: categories,
        periods: const PeriodCalculator(),
        clock: FakeClock(WorkedExample.now),
      )(const NoParams())
          .run();

  group('GetSuggestedLimits (BR-12)', () {
    test('after a full cycle, offers last cycle\'s spend per category rounded up to ₹500', () async {
      useAppAllOfSeptember();
      final Option<Map<int, Money>> limits = (await suggest()).getOrElse((Failure f) => fail(f.message));
      expect(limits.toNullable(), <int, Money>{
        SeedCategoryIds.home: Money.fromMajor(8500),
        SeedCategoryIds.food: Money.fromMajor(10000),
      });
    });

    test('only last cycle counts; this cycle\'s spending is left out', () async {
      useAppAllOfSeptember();
      final Option<Map<int, Money>> limits = (await suggest()).getOrElse((Failure f) => fail(f.message));
      expect(limits.toNullable()?.keys, isNot(contains(SeedCategoryIds.travel)));
    });

    test('first used during the current cycle: no full cycle yet', () async {
      expect(await suggest(), Either<Failure, Option<Map<int, Money>>>.right(const Option<Map<int, Money>>.none()));
    });

    test('first used a day after last cycle began: still not a full cycle', () async {
      addEntry(6000, SeedCategoryIds.food, const CalendarDate(2026, 9, 12), loggedOn: _previousStart.addDays(1));
      expect((await suggest()).getOrElse((Failure f) => fail(f.message)), const Option<Map<int, Money>>.none());
    });

    test('an empty ledger offers nothing', () async {
      ledger.entries.clear();
      expect((await suggest()).getOrElse((Failure f) => fail(f.message)), const Option<Map<int, Money>>.none());
    });

    test('nothing spent last cycle offers nothing', () async {
      addEntry(45000, SeedCategoryIds.salary, _previousStart, kind: EntryKind.got);
      expect((await suggest()).getOrElse((Failure f) => fail(f.message)), const Option<Map<int, Money>>.none());
    });

    test('once any limit is set, the offer is not made again', () async {
      useAppAllOfSeptember();
      categories = FakeCategoryRepository(<Category>[
        Category(
          id: SeedCategoryIds.food,
          key: 'food',
          iconKey: 'food',
          kind: EntryKind.spent,
          sort: 0,
          limit: Option<Money>.of(Money.fromMajor(10000)),
        ),
        ...seedCategories.skip(1),
      ]);
      expect((await suggest()).getOrElse((Failure f) => fail(f.message)), const Option<Map<int, Money>>.none());
    });

    final List<(String, void Function())> failures = <(String, void Function())>[
      ('settings', () => settings.failure = DatabaseFailure('settings')),
      ('rules', () => recurring.failure = DatabaseFailure('rules')),
      ('categories', () => categories.failure = DatabaseFailure('categories')),
      ('entries', () => ledger.failure = DatabaseFailure('entries')),
    ];
    for (final (String name, void Function() breakIt) in failures) {
      test('returns DatabaseFailure when reading $name fails', () async {
        useAppAllOfSeptember();
        breakIt();
        expect((await suggest()).getLeft().toNullable(), isA<DatabaseFailure>());
      });
    }
  });
}
