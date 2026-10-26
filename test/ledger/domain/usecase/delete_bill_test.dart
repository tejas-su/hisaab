import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;

  setUp(() => recurring = FakeRecurringRepository(WorkedExample.rules));

  group('DeleteBill (BR-9: deleting stops future posts, keeps past entries)', () {
    test('stops the rule', () async {
      expect(await DeleteBill(recurring: recurring)(WorkedExample.rent.id).run(), Either<Failure, Unit>.right(unit));
      expect(recurring.rules, isNot(contains(WorkedExample.rent)));
      expect(recurring.stopped, <RecurringRule>[WorkedExample.rent]);
    });

    test('returns RuleNotFoundFailure for an unknown rule', () async {
      expect((await DeleteBill(recurring: recurring)(99).run()).getLeft().toNullable(), isA<RuleNotFoundFailure>());
    });
  });
}
