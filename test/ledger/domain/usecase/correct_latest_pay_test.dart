import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late CorrectLatestPay correct;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    correct = CorrectLatestPay(ledger: ledger);
  });

  Entry pay() => ledger.entries.firstWhere((Entry e) => e.recurringId == WorkedExample.salary.id);

  group('CorrectLatestPay', () {
    test('changes the pay\'s amount and keeps everything else', () async {
      final Entry before = pay();
      final Entry after = (await correct(
        CorrectLatestPayParams(pay: before, amount: Money.fromMajor(50000)),
      ).run()).getOrElse((Failure f) => fail('unexpected $f'));
      expect(after.amount, Money.fromMajor(50000));
      expect(after.date, before.date);
      expect(after.recurringId, before.recurringId);
      expect(after.createdAt, before.createdAt);
      expect(pay(), after);
    });

    test('passes a save failure through', () async {
      ledger.failure = DatabaseFailure('boom');
      expect(
        await correct(CorrectLatestPayParams(pay: pay(), amount: Money.fromMajor(50000))).run(),
        Either<Failure, Entry>.left(DatabaseFailure('boom')),
      );
    });
  });

  test('params compare by their fields', () {
    expect(
      CorrectLatestPayParams(pay: pay(), amount: Money.fromMajor(1)),
      CorrectLatestPayParams(pay: pay(), amount: Money.fromMajor(1)),
    );
  });
}
