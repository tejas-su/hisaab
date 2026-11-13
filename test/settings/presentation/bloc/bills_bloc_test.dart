import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bills_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bills_event.dart';
import 'package:hisaab/settings/presentation/bloc/bills_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillsBloc bloc;
  late FakeLedgerRepository ledger;

  BillsBloc build(FakeRecurringRepository repository) => BillsBloc(
        getBills: GetBills(recurring: repository),
        deleteBill: DeleteBill(recurring: repository),
        restoreBill: RestoreBill(recurring: repository),
        recurring: repository,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: ledger),
        ledger: ledger,
      );

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
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

  group('BillsBloc for savings (D120)', () {
    late BillsBloc savings;

    setUp(() {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      ledger.entries.add(Entry(
        id: 50,
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 10, 10),
        createdAt: WorkedExample.now,
        recurringId: 4,
      ));
      savings = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: ledger),
        ledger: ledger,
        kind: EntryKind.saved,
      );
    });

    tearDown(() => savings.close());

    test('a savings list loads saving rules and the total', () async {
      await savings.dispatch(const BillsLoadRequested());
      expect(
        savings.state,
        BillsReady(
          bills: <RecurringRule>[WorkedExample.rd],
          saved: Option<SavedTotal>.of(SavedTotal(total: Money.fromMajor(5000), since: const CalendarDate(2026, 10, 10))),
        ),
      );
    });

    test('a savings list reloads when an entry changes', () async {
      await savings.dispatch(const BillsLoadRequested());
      await ledger.add(EntryDraft(amount: Money.fromMajor(500), kind: EntryKind.saved, categoryId: SeedCategoryIds.saved, date: WorkedExample.today)).run();
      await pumpEventQueue();
      expect((savings.state as BillsReady).saved.map((SavedTotal t) => t.total), Option<Money>.of(Money.fromMajor(5500)));
    });

    test('a bills list never loads a total', () async {
      await bloc.dispatch(const BillsLoadRequested());
      expect(ready().saved, const Option<SavedTotal>.none());
    });
  });
  group('BillsBloc set aside (AC-Y3, AC-Y4, D177)', () {
    late BillsBloc savings;

    BillsBloc savingsList(FakeLedgerRepository ledger) => BillsBloc(
          getBills: GetBills(recurring: recurring),
          deleteBill: DeleteBill(recurring: recurring),
          restoreBill: RestoreBill(recurring: recurring),
          recurring: recurring,
          haptics: haptics,
          getSavedTotal: GetSavedTotal(ledger: ledger),
          getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
          ledger: ledger,
          kind: EntryKind.saved,
        );

    setUp(() {
      ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.insurance];
      savings = savingsList(ledger);
    });

    tearDown(() => savings.close());

    test("a savings list loads each saving's set-aside beside the put-in total", () async {
      await savings.dispatch(const BillsLoadRequested());

      final BillsReady loaded = savings.state as BillsReady;
      expect(loaded.setAside.map((SetAsideSummary s) => s.perSaving).toNullable(), <int, Money>{5: Money.fromMajor(12000)});
      expect(loaded.saved.map((SavedTotal t) => t.total), Option<Money>.of(Money.fromMajor(12000)));
    });

    test('a ledger write reloads the set-aside, so a Used from the sheet updates the list', () async {
      await savings.dispatch(const BillsLoadRequested());

      await ledger
          .addForSaving(
            EntryDraft(
              amount: Money.fromMajor(4000),
              kind: EntryKind.used,
              categoryId: SeedCategoryIds.saved,
              date: WorkedExample.today,
              note: 'Insurance',
            ),
            savingId: 5,
          )
          .run();
      await pumpEventQueue();

      final BillsReady loaded = savings.state as BillsReady;
      expect(loaded.setAside.map((SetAsideSummary s) => s.stillSetAside), Option<Money>.of(Money.fromMajor(8000)));
      expect(loaded.saved.map((SavedTotal t) => t.total), Option<Money>.of(Money.fromMajor(12000)));
    });

    test('a spent list never calls GetSetAside', () async {
      final BillsBloc spent = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: ledger),
        getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
        ledger: ledger,
      );
      addTearDown(spent.close);
      // why: GetSetAside reads the ledger, so a failing ledger would fail the load if it were called.
      ledger.failure = DatabaseFailure('ledger');

      await spent.dispatch(const BillsLoadRequested());

      expect((spent.state as BillsReady).setAside, const Option<SetAsideSummary>.none());
    });

    test('a savings list built without GetSetAside has no set-aside', () async {
      final BillsBloc plain = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: ledger),
        ledger: ledger,
        kind: EntryKind.saved,
      );
      addTearDown(plain.close);

      await plain.dispatch(const BillsLoadRequested());

      expect((plain.state as BillsReady).setAside, const Option<SetAsideSummary>.none());
    });

    test('a failed set-aside read shows BillsFailed', () async {
      ledger.failure = DatabaseFailure('ledger');

      await savings.dispatch(const BillsLoadRequested());

      expect(savings.state, isA<BillsFailed>());
    });

    test('a delete keeps the set-aside it already loaded', () async {
      await savings.dispatch(const BillsLoadRequested());

      await savings.dispatch(BillsDeleteRequested(WorkedExample.insurance));

      expect((savings.state as BillsReady).setAside.isSome(), isTrue);
    });
  });

  group('BillsBloc a Used save and a saving delete (AC-Y9, AC-Y10)', () {
    late BillsBloc savings;
    late FakeLedgerRepository savingLedger;

    Entry usedEntry() => Entry(
          id: 900,
          amount: Money.fromMajor(4000),
          kind: EntryKind.used,
          categoryId: SeedCategoryIds.saved,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          note: 'Insurance',
          savingId: 5,
        );

    UsedOutcome outcome() => UsedOutcome(entry: usedEntry(), saving: WorkedExample.insurance);

    setUp(() {
      savingLedger = FakeLedgerRepository(<Entry>[...WorkedExample.insurancePutIns]);
      recurring.rules = <RecurringRule>[WorkedExample.insurance];
      savings = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: savingLedger),
        getSetAside: GetSetAside(recurring: recurring, ledger: savingLedger),
        ledger: savingLedger,
        deleteEntry: DeleteEntry(ledger: savingLedger),
        kind: EntryKind.saved,
      );
    });

    tearDown(() async {
      await savings.close();
      await savingLedger.dispose();
    });

    test('BillsUsedDone shows the Undo state once', () async {
      await savings.dispatch(const BillsLoadRequested());

      await savings.dispatch(BillsUsedDone(outcome()));

      expect((savings.state as BillsReady).usedUndo, Option<UsedOutcome>.of(outcome()));
      expect((savings.state as BillsReady).saved.isSome(), isTrue);
    });

    test('BillsUsedDone before the list has loaded does nothing', () async {
      await savings.dispatch(BillsUsedDone(outcome()));

      expect(savings.state, const BillsLoading());
    });

    test('Undo deletes the entry and the list reloads with the money set aside again', () async {
      await savings.dispatch(const BillsLoadRequested());
      await savingLedger.addForSaving(usedEntry().draft, savingId: 5).run();
      await pumpEventQueue();
      final Entry written = savingLedger.entries.last;

      await savings.dispatch(BillsUsedUndoRequested(written));
      await pumpEventQueue();

      expect(savingLedger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
      expect((savings.state as BillsReady).setAside.map((SetAsideSummary s) => s.stillSetAside), Option<Money>.of(Money.fromMajor(12000)));
    });

    test('Undo is quiet when the entry is gone', () async {
      await savings.dispatch(const BillsLoadRequested());

      await savings.dispatch(BillsUsedUndoRequested(usedEntry()));

      expect(savings.state, isA<BillsReady>());
    });

    test('a list built with no DeleteEntry ignores Undo', () async {
      final BillsBloc plain = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: savingLedger),
        ledger: savingLedger,
        kind: EntryKind.saved,
      );
      addTearDown(plain.close);
      savingLedger.entries.add(usedEntry());

      await plain.dispatch(BillsUsedUndoRequested(usedEntry()));

      expect(savingLedger.entries.where((Entry e) => e.id == 900), hasLength(1));
    });

    test('deleting a saving with a put-in offers Undo that says what stays (AC-Y10)', () async {
      await savings.dispatch(const BillsLoadRequested());
      final Future<void> offered = expectLater(
        savings.stream,
        emitsThrough(isA<BillsReady>().having((BillsReady s) => s.undoKeepsHistory, 'keeps history', isTrue)),
      );

      await savings.dispatch(BillsDeleteRequested(WorkedExample.insurance));

      await offered;
    });

    test('deleting a saving with no put-in does not', () async {
      savingLedger.entries.clear();
      await savings.dispatch(const BillsLoadRequested());
      final Future<void> offered = expectLater(
        savings.stream,
        emitsThrough(isA<BillsReady>().having((BillsReady s) => s.undo.isSome(), 'has Undo', isTrue).having((BillsReady s) => s.undoKeepsHistory, 'keeps history', isFalse)),
      );

      await savings.dispatch(BillsDeleteRequested(WorkedExample.insurance));

      await offered;
    });

    test('a failed read of the totals does not stop the delete or the Undo', () async {
      await savings.dispatch(const BillsLoadRequested());
      savingLedger.failure = DatabaseFailure('ledger');

      await savings.dispatch(BillsDeleteRequested(WorkedExample.insurance));

      expect(recurring.stopped, contains(WorkedExample.insurance));
    });

    test('deleting a bill never says what stays', () async {
      recurring.rules = WorkedExample.rules;
      await bloc.dispatch(const BillsLoadRequested());
      final Future<void> offered = expectLater(
        bloc.stream,
        emitsThrough(isA<BillsReady>().having((BillsReady s) => s.undo.isSome(), 'has Undo', isTrue).having((BillsReady s) => s.undoKeepsHistory, 'keeps history', isFalse)),
      );

      await bloc.dispatch(BillsDeleteRequested(WorkedExample.rent));

      await offered;
    });
  });

}
