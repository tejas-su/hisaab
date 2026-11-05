import 'dart:async';

import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_sheet_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_sheet_event.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late FakeHaptics haptics;
  late BillSheetBloc bloc;

  BillSheetBloc build(RecurringRule rule) {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return BillSheetBloc(
      rule: rule,
      editBill: EditBill(recurring: recurring, categories: FakeCategoryRepository(), clock: clock),
      getStatus: GetBillStatus(
        ledger: ledger,
        clock: clock,
        summary: GetCycleSummary(
          ledger: ledger,
          recurring: recurring,
          settings: FakeBudgetSettingsRepository(),
          periods: const PeriodCalculator(),
          clock: clock,
        ),
      ),
      haptics: haptics,
    );
  }

  setUp(() async {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(WorkedExample.entries);
    haptics = FakeHaptics();
    bloc = build(WorkedExample.electricity);
    await pumpEventQueue();
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  BillSheetReady ready() => bloc.state as BillSheetReady;

  Future<void> rebuild(RecurringRule rule) async {
    await bloc.close();
    recurring.rules = <RecurringRule>[rule];
    bloc = build(rule);
    await pumpEventQueue();
  }

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(BillSheetKeyPressed(key));
    }
  }

  group('BillSheetBloc: the bill (FR-SE-1 AC-2)', () {
    test('starts on the bill with its status loaded', () {
      expect(ready().rule, WorkedExample.electricity);
      expect(ready().open, const Option<BillAnswer>.none());
      expect(
        ready().status,
        const Option<BillStatus>.of(BillStatus(nextDate: CalendarDate(2026, 10, 29), daysAway: 3, stamp: BillStampDue(3))),
      );
    });

    test('a status read failure leaves the bill without a stamp', () async {
      ledger.failure = DatabaseFailure('closed');
      await rebuild(WorkedExample.rent);
      expect(ready().status, const Option<BillStatus>.none());
    });
  });

  group('BillSheetBloc: amount (AC-3, AC-4)', () {
    test('opening Amount prefills the rupees; the first key replaces them', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      expect((ready().open, ready().rupees, ready().fresh), (const Option<BillAnswer>.of(BillAnswer.amount), 1200, true));
      await bloc.dispatch(const BillSheetKeyPressed('5'));
      expect((ready().rupees, ready().fresh), (5, false));
      expect(haptics.events, <String>['tick']);
    });

    test('backspace on the prefilled amount removes its last digit', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await bloc.dispatch(const BillSheetBackspacePressed());
      expect((ready().rupees, ready().fresh), (120, false));
    });

    test('clear empties the amount', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await bloc.dispatch(const BillSheetCleared());
      expect(ready().rupees, 0);
    });

    test('a tenth digit is refused with the reject haptic', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await type('999999999');
      haptics.events.clear();
      await bloc.dispatch(const BillSheetKeyPressed('9'));
      expect((ready().rupees, ready().rejections), (999999999, 1));
      expect(haptics.events, <String>['reject']);
    });

    test('keys do nothing on the bill itself', () async {
      await bloc.dispatch(const BillSheetKeyPressed('5'));
      expect(ready().rupees, 0);
      expect(haptics.events, isEmpty);
    });

    test('saving a new amount writes only the amount and returns to the bill', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await type('1350');
      await bloc.dispatch(const BillSheetAmountSaved());
      final RecurringRule saved = recurring.updates.single;
      expect((saved.label, saved.amount, saved.schedule.anchor.day, saved.nextDue, saved.icon), (
        'Electricity',
        Money.fromMajor(1350),
        29,
        WorkedExample.electricity.nextDue,
        const Option<BillIcon>.none(),
      ));
      expect(ready().rule, saved);
      expect(ready().open, const Option<BillAnswer>.none());
      expect(ready().justSaved, const Option<BillAnswer>.of(BillAnswer.amount));
      expect(ready().status.isSome(), isTrue);
      expect(haptics.events.last, 'tick');
    });

    test('saving an unchanged amount writes nothing and returns to the bill', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await bloc.dispatch(const BillSheetAmountSaved());
      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.none());
      expect(ready().justSaved, const Option<BillAnswer>.none());
    });

    test('₹0 is refused', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await bloc.dispatch(const BillSheetCleared());
      await bloc.dispatch(const BillSheetAmountSaved());
      expect(recurring.updates, isEmpty);
      expect((ready().open, ready().rejections), (const Option<BillAnswer>.of(BillAnswer.amount), 1));
      expect(haptics.events.last, 'reject');
    });

    test('two saves back to back write once (droppable; Review Focus 3)', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await type('1350');
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;
      await bloc.dispatch(const BillSheetAmountSaved());
      await bloc.dispatch(const BillSheetAmountSaved());
      gate.complete();
      await pumpEventQueue();
      expect(recurring.updates, hasLength(1));
    });

    test('a failed save keeps the question open, says so and rejects (AC-7)', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await type('1350');
      recurring.failure = DatabaseFailure('disk full');
      await bloc.dispatch(const BillSheetAmountSaved());
      expect((ready().open, ready().saveFailed, ready().saving), (const Option<BillAnswer>.of(BillAnswer.amount), true, false));
      expect(ready().rupees, 1350);
      expect(haptics.events.last, 'reject');
    });
  });

  group('BillSheetBloc: day (AC-4, D34)', () {
    test('a new day saves at once and follows D34', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.day));
      await bloc.dispatch(const BillSheetDayChosen(20));
      expect(recurring.updates.single.nextDue, const CalendarDate(2026, 11, 20));
      expect(recurring.updates.single.amount, WorkedExample.electricity.amount);
      expect(ready().justSaved, const Option<BillAnswer>.of(BillAnswer.day));
    });

    test('the same day writes nothing', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.day));
      await bloc.dispatch(const BillSheetDayChosen(29));
      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.none());
    });

    test('a day tap off the day question is ignored', () async {
      await bloc.dispatch(const BillSheetDayChosen(20));
      expect(recurring.updates, isEmpty);
    });
  });

  group('BillSheetBloc: Amount changes? (D123)', () {
    test('choosing Changes every month saves the mode alone and returns to the bill', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.mode));
      await bloc.dispatch(const BillSheetModeChosen(AmountMode.varies));
      final RecurringRule saved = recurring.updates.single;
      expect(saved.amountMode, AmountMode.varies);
      expect((saved.amount, saved.nextDue, saved.label), (WorkedExample.electricity.amount, WorkedExample.electricity.nextDue, 'Electricity'));
      expect(ready().justSaved, const Option<BillAnswer>.of(BillAnswer.mode));
      expect(ready().rule.amountMode, AmountMode.varies);
    });

    test('the same mode writes nothing', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.mode));
      await bloc.dispatch(const BillSheetModeChosen(AmountMode.fixed));
      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.none());
    });

    test('a mode tap off the question is ignored', () async {
      await bloc.dispatch(const BillSheetModeChosen(AmountMode.card));
      expect(recurring.updates, isEmpty);
    });

    test('changing the amount of a changing bill keeps it changing', () async {
      await rebuild(WorkedExample.electricity.copyWith(amountMode: AmountMode.varies));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await type('1500');
      await bloc.dispatch(const BillSheetAmountSaved());
      expect(recurring.updates.single.amountMode, AmountMode.varies);
    });
  });

  group('BillSheetBloc: name (AC-4)', () {
    test('opening Name starts the draft from the current name', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.name));
      expect(ready().draftName, 'Electricity');
    });

    test('saves the trimmed name', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.name));
      await bloc.dispatch(const BillSheetNameChanged('  Airtel fibre '));
      await bloc.dispatch(const BillSheetNameSaved());
      expect(recurring.updates.single.label, 'Airtel fibre');
      expect(ready().justSaved, const Option<BillAnswer>.of(BillAnswer.name));
    });

    test('a blank name is ignored', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.name));
      await bloc.dispatch(const BillSheetNameChanged('   '));
      await bloc.dispatch(const BillSheetNameSaved());
      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.of(BillAnswer.name));
    });

    test('an unchanged name writes nothing', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.name));
      await bloc.dispatch(const BillSheetNameChanged('Electricity '));
      await bloc.dispatch(const BillSheetNameSaved());
      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.none());
    });

    test('renaming keeps an icon picked by hand (Review Focus 5)', () async {
      await rebuild(WorkedExample.electricity.copyWith(icon: const Option<BillIcon>.of(BillIcon.car)));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.name));
      await bloc.dispatch(const BillSheetNameChanged('Gas'));
      await bloc.dispatch(const BillSheetNameSaved());
      expect(recurring.updates.single.icon, const Option<BillIcon>.of(BillIcon.car));
    });
  });

  group('BillSheetBloc: icon (AC-4, BR-9)', () {
    test('picking another icon stores the pick', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.icon));
      await bloc.dispatch(const BillSheetIconChosen(BillIcon.card));
      expect(recurring.updates.single.icon, const Option<BillIcon>.of(BillIcon.card));
      expect(ready().justSaved, const Option<BillAnswer>.of(BillAnswer.icon));
    });

    test('picking the icon the name suggests clears a hand pick', () async {
      await rebuild(WorkedExample.electricity.copyWith(icon: const Option<BillIcon>.of(BillIcon.car)));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.icon));
      await bloc.dispatch(const BillSheetIconChosen(BillIcon.power));
      expect(recurring.updates.single.icon, const Option<BillIcon>.none());
    });

    test('picking the icon already shown writes nothing', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.icon));
      await bloc.dispatch(const BillSheetIconChosen(BillIcon.power));
      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.none());
    });
  });

  group('BillSheetBloc: leaving (AC-5, AC-6)', () {
    test('back from a question returns to the bill and drops the typing', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
      await type('9');
      await bloc.dispatch(const BillSheetBackPressed());
      expect(ready().open, const Option<BillAnswer>.none());
      expect(recurring.updates, isEmpty);
    });

    test('back on the bill closes it unchanged when nothing was saved', () async {
      await bloc.dispatch(const BillSheetBackPressed());
      expect(bloc.state, const BillSheetClosed(BillSheetUnchanged()));
    });

    test('back on the bill closes it changed after a save', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.day));
      await bloc.dispatch(const BillSheetDayChosen(20));
      await bloc.dispatch(const BillSheetBackPressed());
      expect(bloc.state, BillSheetClosed(BillSheetChanged(recurring.updates.single)));
    });

    test('the outcome when dismissed follows what was saved', () async {
      expect(ready().outcome, const BillSheetUnchanged());
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.day));
      await bloc.dispatch(const BillSheetDayChosen(20));
      expect(ready().outcome, BillSheetChanged(recurring.updates.single));
    });

    test('delete closes with the rule for the opening screen to delete; nothing is deleted here', () async {
      await bloc.dispatch(const BillSheetDeleteRequested());
      expect(bloc.state, BillSheetClosed(BillSheetDeleted(WorkedExample.electricity)));
      expect(recurring.rules, contains(WorkedExample.electricity));
    });

    test('the saved note expires', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.day));
      await bloc.dispatch(const BillSheetDayChosen(20));
      await bloc.dispatch(const BillSheetSavedNoteExpired());
      expect(ready().justSaved, const Option<BillAnswer>.none());
    });

    test('closing mid-save does not throw', () async {
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.day));
      bloc.add(const BillSheetDayChosen(20));
      await expectLater(bloc.close(), completes);
    });
  });

  test('events and outcomes compare by their fields', () {
    expect(const BillSheetAnswerOpened(BillAnswer.day), const BillSheetAnswerOpened(BillAnswer.day));
    expect(const BillSheetKeyPressed('5').props, <Object?>['5']);
    expect(const BillSheetDayChosen(3).props, <Object?>[3]);
    expect(const BillSheetNameChanged('A').props, <Object?>['A']);
    expect(const BillSheetIconChosen(BillIcon.gas).props, <Object?>[BillIcon.gas]);
    expect(const BillSheetStatusRequested().props, isEmpty);
    expect(const BillSheetUnchanged().props, isEmpty);
    expect(const BillSheetModeChosen(AmountMode.card).props, <Object?>[AmountMode.card]);
  });
}
