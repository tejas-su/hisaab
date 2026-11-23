import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bills_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bills_event.dart';
import 'package:hisaab/settings/presentation/bloc/bills_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// *I bought it* from the Savings list: one Undo restores the saving and the money (AC-T9, E152).
void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late BillsBloc savings;

  BillsBloc build({bool withDeleteEntry = true}) => BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: FakeHaptics(),
        getSavedTotal: GetSavedTotal(ledger: ledger),
        getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
        ledger: ledger,
        deleteEntry: withDeleteEntry ? DeleteEntry(ledger: ledger) : null,
        kind: EntryKind.saved,
      );

  Entry used() => Entry(
        id: 900,
        amount: Money.fromMajor(12000),
        kind: EntryKind.used,
        categoryId: SeedCategoryIds.saved,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        note: 'Insurance',
        savingId: 5,
      );

  UsedOutcome outcome() => UsedOutcome(entry: used(), saving: WorkedExample.insurance);

  setUp(() async {
    recurring = FakeRecurringRepository(<RecurringRule>[WorkedExample.insurance]);
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.insurancePutIns, used()]);
    await recurring.setActive(5, active: false).run();
    savings = build();
  });

  tearDown(() async {
    await savings.close();
    await recurring.dispose();
    await ledger.dispose();
  });

  test('BillsBoughtDone offers its Undo once and keeps the put-in total', () async {
    await savings.dispatch(const BillsLoadRequested());

    await savings.dispatch(BillsBoughtDone(outcome()));

    expect((savings.state as BillsReady).boughtUndo, Option<UsedOutcome>.of(outcome()));
    expect((savings.state as BillsReady).saved.isSome(), isTrue);
  });

  test('BillsBoughtDone before the list has loaded does nothing', () async {
    await savings.dispatch(BillsBoughtDone(outcome()));

    expect(savings.state, const BillsLoading());
  });

  test('Undo brings the saving back and deletes the Used entry', () async {
    await savings.dispatch(const BillsLoadRequested());

    await savings.dispatch(BillsBoughtUndoRequested(outcome()));
    await pumpEventQueue();

    expect(recurring.rules.map((RecurringRule r) => r.id), <int>[5]);
    expect(ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
    expect((savings.state as BillsReady).bills.single.id, 5);
  });

  test('a failed restore deletes nothing', () async {
    await savings.dispatch(const BillsLoadRequested());
    recurring.failure = DatabaseFailure('recurring');

    await savings.dispatch(BillsBoughtUndoRequested(outcome()));

    expect(ledger.entries.where((Entry e) => e.kind == EntryKind.used), hasLength(1));
  });

  test('a list built with no DeleteEntry ignores Undo', () async {
    await savings.close();
    savings = build(withDeleteEntry: false);

    await savings.dispatch(BillsBoughtUndoRequested(outcome()));

    expect(recurring.rules, isEmpty);
  });

  test('the events compare by their fields', () {
    expect(BillsBoughtDone(outcome()).props, <Object?>[outcome()]);
    expect(BillsBoughtUndoRequested(outcome()).props, <Object?>[outcome()]);
  });
}
