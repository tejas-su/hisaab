import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/cubit/bills_cubit.dart';
import 'package:expense_tracker/settings/presentation/cubit/bills_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillsCubit cubit;

  BillsCubit build(FakeRecurringRepository repository) => BillsCubit(
        getBills: GetBills(recurring: repository),
        deleteBill: DeleteBill(recurring: repository),
        restoreBill: RestoreBill(recurring: repository),
        recurring: repository,
        haptics: haptics,
      );

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    haptics = FakeHaptics();
    cubit = build(recurring);
  });

  tearDown(() async {
    await cubit.close();
    await recurring.dispose();
  });

  BillsReady ready() => cubit.state as BillsReady;

  group('BillsCubit.load (FR-SE-1)', () {
    test('starts loading', () => expect(cubit.state, const BillsLoading()));

    test('lists the bills, soonest first', () async {
      await cubit.load();
      expect(cubit.state, BillsReady(bills: <RecurringRule>[WorkedExample.electricity, WorkedExample.rent]));
    });

    test('emits BillsFailed when the rules can\'t be read', () async {
      recurring.failure = DatabaseFailure('locked');
      await cubit.load();
      expect(cubit.state, isA<BillsFailed>());
    });

    test('reloads when a bill is added or edited elsewhere', () async {
      await cubit.load();
      final Future<void> reloaded = expectLater(
        cubit.stream,
        emitsThrough(isA<BillsReady>().having((BillsReady s) => s.bills.length, 'bills', 1)),
      );
      await recurring.setActive(WorkedExample.rent.id, active: false).run();
      await reloaded;
    });

    test('closing mid-load does not throw', () async {
      final Future<void> loading = cubit.load();
      await cubit.close();
      await expectLater(loading, completes);
    });
  });

  group('BillsCubit delete and undo', () {
    setUp(() => cubit.load());

    test('removes the row at once, then offers Undo for it', () async {
      final Future<void> undoOffered = expectLater(
        cubit.stream,
        emitsThrough(isA<BillsReady>().having((BillsReady s) => s.undo, 'undo', Option<RecurringRule>.of(WorkedExample.rent))),
      );
      final Future<void> deleting = cubit.delete(WorkedExample.rent);
      expect(ready().bills, isNot(contains(WorkedExample.rent)), reason: 'Dismissible needs the row gone synchronously');
      await deleting;
      await undoOffered;
      expect(recurring.stopped, <RecurringRule>[WorkedExample.rent]);
    });

    test('undo brings the bill back', () async {
      await cubit.delete(WorkedExample.rent);
      await cubit.undo(WorkedExample.rent);
      await cubit.load();
      expect(ready().bills, contains(WorkedExample.rent));
    });

    test('a failed delete reloads the list as it really is', () async {
      recurring.rules = <RecurringRule>[WorkedExample.electricity];
      await cubit.delete(WorkedExample.rent);
      expect(ready().bills, <RecurringRule>[WorkedExample.electricity]);
      expect(ready().undo, const Option<RecurringRule>.none());
    });

    test('a failed undo is quiet', () async {
      await cubit.undo(WorkedExample.rent);
      expect(recurring.rules, WorkedExample.rules);
    });

    test('delete does nothing before the list has loaded', () async {
      final BillsCubit fresh = build(recurring);
      addTearDown(fresh.close);
      await fresh.delete(WorkedExample.rent);
      expect(recurring.stopped, isEmpty);
    });

    test('closing mid-delete does not throw', () async {
      final Future<void> deleting = cubit.delete(WorkedExample.rent);
      await cubit.close();
      await expectLater(deleting, completes);
    });

    test('crossing the swipe threshold plays one light haptic', () {
      cubit.swipeThresholdReached();
      expect(haptics.events, <String>['threshold']);
    });
  });

  test('bill list states compare by their fields', () {
    expect(const BillsLoading().props, isEmpty);
    final Failure failure = DatabaseFailure('locked');
    expect(BillsFailed(failure).props, <Object?>[failure]);
  });
}
