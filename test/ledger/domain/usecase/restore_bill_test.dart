import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;

  setUp(() => recurring = FakeRecurringRepository(WorkedExample.rules));

  group('RestoreBill (Undo)', () {
    test('brings a stopped rule back', () async {
      await DeleteBill(recurring: recurring)(WorkedExample.rent.id).run();
      expect(await RestoreBill(recurring: recurring)(WorkedExample.rent.id).run(), Either<Failure, Unit>.right(unit));
      expect(recurring.rules, contains(WorkedExample.rent));
      expect(recurring.stopped, isEmpty);
    });

    test('returns RuleNotFoundFailure when nothing was stopped', () async {
      expect((await RestoreBill(recurring: recurring)(WorkedExample.rent.id).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });
  });
}
