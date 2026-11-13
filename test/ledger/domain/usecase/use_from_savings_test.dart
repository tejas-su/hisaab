import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:hisaab/ledger/domain/usecase/use_from_savings.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late UseFromSavings useFromSavings;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
    categories = FakeCategoryRepository();
    useFromSavings = UseFromSavings(ledger: ledger, categories: categories, clock: FakeClock(WorkedExample.now));
  });

  tearDown(() => ledger.dispose());

  Future<Either<Failure, Entry>> use(int rupees) =>
      useFromSavings(UseFromSavingsParams(saving: WorkedExample.insurance, amount: Money.fromMajor(rupees))).run();

  Future<Entry> useOk(int rupees) async => (await use(rupees)).getOrElse((Failure f) => fail(f.message));

  group('UseFromSavings (BR-19, D175)', () {
    test('saves a used entry: kind, today, note = the saving, saving_id, hidden saved category', () async {
      final Entry entry = await useOk(4000);

      expect(
        (entry.amount, entry.kind, entry.categoryId, entry.date, entry.note, entry.savingId, entry.recurringId),
        (Money.fromMajor(4000), EntryKind.used, SeedCategoryIds.saved, WorkedExample.today, 'Insurance', 5, null),
      );
      expect(ledger.entries.last, entry);
    });

    test('₹0 is InvalidAmountFailure and writes nothing', () async {
      expect((await use(0)).getLeft().toNullable(), isA<InvalidAmountFailure>());
      expect(ledger.saved, isEmpty);
    });

    test('a 10th digit is InvalidAmountFailure', () async {
      expect((await use(1000000000)).getLeft().toNullable(), isA<InvalidAmountFailure>());
    });

    test('more than is set aside is UsedTooMuchFailure and writes nothing (E94)', () async {
      expect((await use(15000)).getLeft().toNullable(), isA<UsedTooMuchFailure>());
      expect(ledger.saved, isEmpty);
    });

    test('exactly what is set aside is accepted (E94 boundary)', () async {
      expect((await useOk(12000)).amount, Money.fromMajor(12000));
    });

    test('one rupee over what is set aside is refused', () async {
      expect((await use(12001)).getLeft().toNullable(), isA<UsedTooMuchFailure>());
    });

    test('a set-aside under one rupee refuses any amount (U6)', () async {
      ledger.entries
        ..removeWhere((Entry e) => e.kind == EntryKind.saved && e.recurringId == 5)
        ..add(Entry(
          id: 300,
          amount: const Money(50),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          recurringId: 5,
        ));

      expect((await use(1)).getLeft().toNullable(), isA<UsedTooMuchFailure>());
    });

    test('the set-aside is re-read in the write: a put-in deleted since the sheet opened refuses (E99)', () async {
      ledger.entries.removeWhere((Entry e) => e.id >= 105 && e.id <= 111);

      expect((await use(12000)).getLeft().toNullable(), isA<UsedTooMuchFailure>());
      expect((await useOk(5000)).amount, Money.fromMajor(5000));
    });

    test('a second use up to what is left is accepted; one past it is refused (E96)', () async {
      await useOk(7000);

      expect((await use(6000)).getLeft().toNullable(), isA<UsedTooMuchFailure>());
      expect((await useOk(5000)).amount, Money.fromMajor(5000));
      expect((await use(1)).getLeft().toNullable(), isA<UsedTooMuchFailure>());
    });

    test('a database failure on the read is passed through', () async {
      ledger.failure = DatabaseFailure('ledger');

      expect((await use(100)).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('a failure finding the saved category is passed through and writes nothing', () async {
      categories.failure = DatabaseFailure('categories');

      expect((await use(100)).getLeft().toNullable(), isA<DatabaseFailure>());
      expect(ledger.saved, isEmpty);
    });
  });
  test('the params compare by saving and amount', () {
    final UseFromSavingsParams params = UseFromSavingsParams(saving: WorkedExample.insurance, amount: Money.fromMajor(5));

    expect(params, UseFromSavingsParams(saving: WorkedExample.insurance, amount: Money.fromMajor(5)));
    expect(params, isNot(UseFromSavingsParams(saving: WorkedExample.insurance, amount: Money.fromMajor(6))));
  });

}
