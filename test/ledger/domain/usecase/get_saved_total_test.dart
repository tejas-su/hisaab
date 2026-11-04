import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/domain/entities/entry.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/saved_total.dart';
import 'package:expense_tracker/ledger/domain/usecase/get_saved_total.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;

  setUp(() => ledger = FakeLedgerRepository(WorkedExample.entries));
  tearDown(() => ledger.dispose());

  Entry saved(int id, int rupees, CalendarDate date) => Entry(
        id: id,
        amount: Money.fromMajor(rupees),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: date,
        createdAt: WorkedExample.now,
      );

  group('GetSavedTotal (D120)', () {
    test('none with no saves', () async {
      expect(await GetSavedTotal(ledger: ledger)(const NoParams()).run(), Either<Failure, Option<SavedTotal>>.right(const Option<SavedTotal>.none()));
    });

    test('₹5,500 since 10 Oct', () async {
      ledger.entries
        ..add(saved(50, 5000, const CalendarDate(2026, 10, 10)))
        ..add(saved(51, 500, WorkedExample.today));
      expect(
        await GetSavedTotal(ledger: ledger)(const NoParams()).run(),
        Either<Failure, Option<SavedTotal>>.right(
          Option<SavedTotal>.of(SavedTotal(total: Money.fromMajor(5500), since: const CalendarDate(2026, 10, 10))),
        ),
      );
    });
  });
}
