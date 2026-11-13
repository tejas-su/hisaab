import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/entities/set_aside_summary.dart';
import 'package:hisaab/ledger/domain/usecase/get_set_aside.dart';

import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late GetSetAside getSetAside;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
    recurring = FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, WorkedExample.insurance]);
    getSetAside = GetSetAside(recurring: recurring, ledger: ledger);
  });

  tearDown(() => ledger.dispose());

  Future<Either<Failure, SetAsideSummary>> run() => getSetAside(const NoParams()).run();

  group('GetSetAside (BR-19)', () {
    test('reads the active savings and the put-ins from the ledger', () async {
      final SetAsideSummary summary = (await run()).getOrElse((Failure f) => fail(f.message));

      expect(summary.perSaving, <int, Money>{5: Money.fromMajor(12000)});
      expect(summary.stillSetAside, Money.fromMajor(12000));
      expect(summary.anyUse, isFalse);
    });

    test('a use is taken off', () async {
      ledger.entries.add(Entry(
        id: 900,
        amount: Money.fromMajor(4000),
        kind: EntryKind.used,
        categoryId: SeedCategoryIds.saved,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        savingId: 5,
      ));

      final SetAsideSummary summary = (await run()).getOrElse((Failure f) => fail(f.message));

      expect(summary.stillSetAside, Money.fromMajor(8000));
      expect(summary.anyUse, isTrue);
    });

    test('with no saving the summary is empty', () async {
      recurring.rules = WorkedExample.rules;

      expect((await run()).getOrElse((Failure f) => fail(f.message)).perSaving, isEmpty);
    });

    test('a failed rules read is passed through', () async {
      recurring.failure = DatabaseFailure('rules');

      expect((await run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('a failed ledger read is passed through', () async {
      ledger.failure = DatabaseFailure('ledger');

      expect((await run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
