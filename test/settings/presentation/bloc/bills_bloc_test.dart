import 'dart:async';

import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bills_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/bills_event.dart';
import 'package:expense_tracker/settings/presentation/bloc/bills_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillsBloc bloc;

  BillsBloc build(FakeRecurringRepository repository) => BillsBloc(
        getBills: GetBills(recurring: repository),
        deleteBill: DeleteBill(recurring: repository),
        restoreBill: RestoreBill(recurring: repository),
        recurring: repository,
        haptics: haptics,
      );

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    haptics = FakeHaptics();
    bloc = build(recurring);
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  BillsReady ready() => bloc.state as BillsReady;

  group('BillsBloc load (FR-SE-1)', () {
    test('starts loading', () => expect(bloc.state, const BillsLoading()));

    test('lists the bills, soonest first', () async {
      await bloc.dispatch(const BillsLoadRequested());
      expect(bloc.state, BillsReady(bills: <RecurringRule>[WorkedExample.electricity, WorkedExample.rent]));
    });

    test('emits BillsFailed when the rules can\'t be read', () async {
      recurring.failure = DatabaseFailure('locked');
      await bloc.dispatch(const BillsLoadRequested());
      expect(bloc.state, isA<BillsFailed>());
    });

    test('reloads when a bill is added or edited elsewhere', () async {
      await bloc.dispatch(const BillsLoadRequested());
      final Future<void> reloaded = expectLater(
        bloc.stream,
        emitsThrough(isA<BillsReady>().having((BillsReady s) => s.bills.length, 'bills', 1)),
      );
      await recurring.setActive(WorkedExample.rent.id, active: false).run();
      await reloaded;
    });

    test('a newer load wins over a slower older one', () async {
      final Completer<void> slowRead = Completer<void>();
      recurring.nextReadGate = slowRead;
      bloc.add(const BillsLoadRequested());
      await pumpEventQueue();
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      await bloc.dispatch(const BillsLoadRequested());
      slowRead.complete();
      await pumpEventQueue();
      expect(ready().bills, <RecurringRule>[WorkedExample.rent]);
    });

    test('closing mid-load does not throw', () async {
      bloc.add(const BillsLoadRequested());
      await expectLater(bloc.close(), completes);
    });
  });

  group('BillsBloc delete and undo', () {
    setUp(() => bloc.dispatch(const BillsLoadRequested()));

    test('removes the row first, then offers Undo for it', () async {
      final Future<void> states = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<BillsReady>()
              .having((BillsReady s) => s.bills, 'bills', isNot(contains(WorkedExample.rent)))
              .having((BillsReady s) => s.undo, 'undo', const Option<RecurringRule>.none()),
          isA<BillsReady>().having((BillsReady s) => s.undo, 'undo', Option<RecurringRule>.of(WorkedExample.rent)),
        ]),
      );
      await bloc.dispatch(BillsDeleteRequested(WorkedExample.rent));
      await states;
      expect(recurring.stopped, <RecurringRule>[WorkedExample.rent]);
    });

    test('undo brings the bill back', () async {
      await bloc.dispatch(BillsDeleteRequested(WorkedExample.rent));
      await bloc.dispatch(BillsUndoRequested(WorkedExample.rent));
      await bloc.dispatch(const BillsLoadRequested());
      expect(ready().bills, contains(WorkedExample.rent));
    });

    test('a failed delete reloads the list as it really is', () async {
      recurring.rules = <RecurringRule>[WorkedExample.electricity];
      await bloc.dispatch(BillsDeleteRequested(WorkedExample.rent));
      expect(ready().bills, <RecurringRule>[WorkedExample.electricity]);
      expect(ready().undo, const Option<RecurringRule>.none());
    });

    test('a failed undo is quiet', () async {
      await bloc.dispatch(BillsUndoRequested(WorkedExample.rent));
      expect(recurring.rules, WorkedExample.rules);
    });

    test('delete does nothing before the list has loaded', () async {
      final BillsBloc fresh = build(recurring);
      addTearDown(fresh.close);
      await fresh.dispatch(BillsDeleteRequested(WorkedExample.rent));
      expect(recurring.stopped, isEmpty);
    });

    test('closing mid-delete does not throw', () async {
      bloc.add(BillsDeleteRequested(WorkedExample.rent));
      await expectLater(bloc.close(), completes);
    });

    test('crossing the swipe threshold plays one light haptic', () async {
      await bloc.dispatch(const BillsSwipeThresholdReached());
      expect(haptics.events, <String>['threshold']);
    });
  });

  test('bill list states compare by their fields', () {
    expect(const BillsLoading().props, isEmpty);
    final Failure failure = DatabaseFailure('locked');
    expect(BillsFailed(failure).props, <Object?>[failure]);
  });

  test('bill list events compare by their fields', () {
    expect(const BillsLoadRequested().props, isEmpty);
    expect(BillsDeleteRequested(WorkedExample.rent).props, <Object?>[WorkedExample.rent]);
    expect(BillsUndoRequested(WorkedExample.rent), BillsUndoRequested(WorkedExample.rent));
  });
}
