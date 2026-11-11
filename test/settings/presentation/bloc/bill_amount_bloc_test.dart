import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_amount_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bill_amount_event.dart';
import 'package:hisaab/settings/presentation/bloc/bill_amount_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const CalendarDate _oct20 = CalendarDate(2026, 10, 20);

final RecurringRule _electricity = RecurringRule(
  id: 8,
  label: 'Electricity',
  amount: Money.fromMajor(1200),
  kind: EntryKind.spent,
  categoryId: 5,
  schedule: const Schedule(frequency: Frequency.monthly, anchor: _oct20),
  nextDue: _oct20,
  amountMode: AmountMode.varies,
);

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillAmountBloc bloc;

  BillAmountBloc build() => BillAmountBloc(
        occurrence: Occurrence(rule: _electricity, date: _oct20),
        getLastAmount: GetLastBillAmount(ledger: ledger, clock: FakeClock(WorkedExample.now)),
        enter: EnterBillAmount(ledger: ledger, recurring: recurring),
        skip: SkipBillOccurrence(recurring: recurring),
        haptics: haptics,
      );

  setUp(() async {
    ledger = FakeLedgerRepository();
    recurring = FakeRecurringRepository(<RecurringRule>[_electricity]);
    haptics = FakeHaptics();
    bloc = build();
    await bloc.dispatch(const BillAmountLoadRequested());
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  BillAmountEditing editing() => bloc.state as BillAmountEditing;

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(BillAmountKeyPressed(key));
    }
  }

  group('BillAmountBloc (D123)', () {
    test('starts loading, then prefills the estimate, fresh', () {
      expect(build().state, const BillAmountLoading());
      expect(editing().rupees, 1200);
      expect(editing().fresh, isTrue);
      expect(editing().lastTime, const Option<Money>.none());
    });

    test('knows the amount entered last time', () async {
      ledger.entries.add(Entry(
        id: 1,
        amount: Money.fromMajor(1300),
        kind: EntryKind.spent,
        categoryId: 5,
        date: const CalendarDate(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
        recurringId: 8,
      ));
      await bloc.dispatch(const BillAmountLoadRequested());
      expect(editing().lastTime, Option<Money>.of(Money.fromMajor(1300)));
    });

    test('a failed history read still opens the keypad, without "last time"', () async {
      ledger.failure = DatabaseFailure('disk');
      await bloc.dispatch(const BillAmountLoadRequested());
      expect(editing().rupees, 1200);
      expect(editing().lastTime, const Option<Money>.none());
    });

    test('the first key replaces the estimate', () async {
      await type('460');
      expect(editing().rupees, 460);
      expect(haptics.events, everyElement('tick'));
    });

    test('backspace and clear edit the amount', () async {
      await bloc.dispatch(const BillAmountBackspacePressed());
      expect(editing().rupees, 120);
      await bloc.dispatch(const BillAmountCleared());
      expect(editing().rupees, 0);
    });

    test('a tenth digit is refused with the reject haptic', () async {
      await type('999999999');
      await bloc.dispatch(const BillAmountKeyPressed('9'));
      expect(editing().rupees, 999999999);
      expect(editing().rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('Save enters the typed amount', () async {
      await type('1460');
      await bloc.dispatch(const BillAmountSavePressed());
      final BillAmountDone done = bloc.state as BillAmountDone;
      expect(done.outcome, isA<BillAmountWasEntered>());
      expect(ledger.entries.single.amount, Money.fromMajor(1460));
      expect(haptics.events.last, 'tick');
    });

    test('Save untouched enters the estimate: same as last time in one tap', () async {
      await bloc.dispatch(const BillAmountSavePressed());
      expect(ledger.entries.single.amount, Money.fromMajor(1200));
    });

    test('Save at ₹0 writes nothing', () async {
      await bloc.dispatch(const BillAmountCleared());
      await bloc.dispatch(const BillAmountSavePressed());
      expect(ledger.entries, isEmpty);
      expect(bloc.state, isA<BillAmountEditing>());
    });

    test('Didn\'t go out skips it', () async {
      await bloc.dispatch(const BillAmountSkipPressed());
      expect(
        (bloc.state as BillAmountDone).outcome,
        BillAmountWasSkipped(occurrence: Occurrence(rule: _electricity, date: _oct20), skip: const BillSkip(ruleId: 8, date: _oct20)),
      );
      expect(recurring.skips, hasLength(1));
    });

    test('a second Save while the first is in flight writes once (droppable)', () async {
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;
      bloc.add(const BillAmountSavePressed());
      await pumpEventQueue();
      bloc.add(const BillAmountSavePressed());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();
      expect(ledger.entries, hasLength(1));
    });

    test('a second skip while the first is in flight skips once (droppable)', () async {
      bloc
        ..add(const BillAmountSkipPressed())
        ..add(const BillAmountSkipPressed());
      await pumpEventQueue();
      expect(recurring.skips, hasLength(1));
    });

    test('a failed save says so, rejects, and stays open', () async {
      ledger.failure = DatabaseFailure('disk');
      await bloc.dispatch(const BillAmountSavePressed());
      expect(editing().saveFailed, isTrue);
      expect(editing().saving, isFalse);
      expect(haptics.events.last, 'reject');
    });

    test('a failed skip says so and stays open', () async {
      recurring.failure = DatabaseFailure('disk');
      await bloc.dispatch(const BillAmountSkipPressed());
      expect(editing().saveFailed, isTrue);
    });

    test('keys do nothing while loading or saving', () async {
      final BillAmountBloc fresh = build();
      addTearDown(fresh.close);
      await fresh.dispatch(const BillAmountKeyPressed('5'));
      expect(fresh.state, const BillAmountLoading());
    });

    test('events and states compare by their fields', () {
      expect(const BillAmountLoadRequested().props, isEmpty);
      expect(const BillAmountKeyPressed('5').props, <Object?>['5']);
      expect(const BillAmountSkipPressed(), const BillAmountSkipPressed());
      expect(const BillAmountLoading().props, isEmpty);
      final BillAmountOutcome skipped = BillAmountWasSkipped(
        occurrence: Occurrence(rule: _electricity, date: _oct20),
        skip: const BillSkip(ruleId: 8, date: _oct20),
      );
      expect(BillAmountDone(skipped).props, <Object?>[skipped]);
    });

    test('closing mid-save completes', () async {
      bloc.add(const BillAmountSavePressed());
      await expectLater(bloc.close(), completes);
    });
  });
}
