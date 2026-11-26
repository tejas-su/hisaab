import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_event.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// *Saving up to* and the reached choices on a saving's sheet (SPEC BR-23, FR-SE-1 AC-T1 to AC-T11).
///
/// Insurance puts in ₹1,000 on the 5th and has ₹12,000 set aside.
void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeHaptics haptics;
  late BillSheetBloc bloc;

  BillSheetBloc build(RecurringRule rule) {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return BillSheetBloc(
      rule: rule,
      editBill: EditBill(recurring: recurring, categories: categories, clock: clock),
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
      getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
      useFromSavings: UseFromSavings(ledger: ledger, categories: categories, clock: clock),
      deleteBill: DeleteBill(recurring: recurring),
      deleteEntry: DeleteEntry(ledger: ledger),
      clock: clock,
    );
  }

  Future<void> open(RecurringRule rule) async {
    recurring.rules = <RecurringRule>[...WorkedExample.rules, rule];
    bloc = build(rule);
    await pumpEventQueue();
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
    await ledger.dispose();
  });

  BillSheetReady ready() => bloc.state as BillSheetReady;

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(BillSheetKeyPressed(key));
    }
  }

  RecurringRule withTarget(int rupees, {Option<Money>? reachedFor, Option<CalendarDate>? reachedOn}) =>
      WorkedExample.insurance.copyWith(
        target: Option<Money>.of(Money.fromMajor(rupees)),
        targetReachedFor: reachedFor,
        targetReachedOn: reachedOn,
      );

  group('opening Saving up to (AC-T2)', () {
    test("with no target the amount is empty, never the saving's monthly amount", () async {
      await open(WorkedExample.insurance);

      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      expect((ready().open, ready().rupees, ready().fresh), (const Option<BillAnswer>.of(BillAnswer.target), 0, true));
    });

    test('with a target it is prefilled, and the first key replaces it (FR-AD-8)', () async {
      await open(withTarget(50000));

      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      expect((ready().rupees, ready().fresh), (50000, true));

      await bloc.dispatch(const BillSheetKeyPressed('6'));
      expect((ready().rupees, ready().fresh), (6, false));
      expect(haptics.events, <String>['tick']);
    });

    test('backspace and clear edit the target too', () async {
      await open(withTarget(50000));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      await bloc.dispatch(const BillSheetBackspacePressed());
      expect(ready().rupees, 5000);
      await bloc.dispatch(const BillSheetCleared());
      expect(ready().rupees, 0);
    });

    test('the sheet knows today, for the year on the estimate', () async {
      await open(WorkedExample.insurance);

      expect(ready().today, const Option<CalendarDate>.of(WorkedExample.today));
    });
  });

  group('Save (AC-T4, F1, F4)', () {
    test('a target above what is set aside writes only the target and returns to the sheet', () async {
      await open(WorkedExample.insurance);
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      await type('50000');

      await bloc.dispatch(const BillSheetTargetSaved());

      final RecurringRule saved = recurring.updates.single;
      expect((saved.target, saved.targetReachedFor, saved.targetReachedOn), (
        Option<Money>.of(Money.fromMajor(50000)),
        const Option<Money>.none(),
        const Option<CalendarDate>.none(),
      ));
      expect((saved.amount, saved.label, saved.nextDue), (WorkedExample.insurance.amount, 'Insurance', WorkedExample.insurance.nextDue));
      expect((ready().open, ready().justSaved, ready().changed), (
        const Option<BillAnswer>.none(),
        const Option<BillAnswer>.of(BillAnswer.target),
        true,
      ));
      expect(ready().rule, saved);
      expect(haptics.events.last, 'tick');
    });

    test('a target at or below what is set aside also writes target_reached_for, never target_reached_on (F1, E129)', () async {
      await open(withTarget(
        8000,
        reachedFor: Option<Money>.of(Money.fromMajor(8000)),
        reachedOn: const Option<CalendarDate>.of(WorkedExample.today),
      ));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      await type('12000');

      await bloc.dispatch(const BillSheetTargetSaved());

      final RecurringRule saved = recurring.updates.single;
      expect((saved.target, saved.targetReachedFor, saved.targetReachedOn), (
        Option<Money>.of(Money.fromMajor(12000)),
        Option<Money>.of(Money.fromMajor(12000)),
        const Option<CalendarDate>.none(),
      ));
    });

    test('a raised target above what is set aside keeps the old reached columns, so the line can show again (E146)', () async {
      final Option<Money> reachedFor = Option<Money>.of(Money.fromMajor(8000));
      const Option<CalendarDate> reachedOn = Option<CalendarDate>.of(CalendarDate(2026, 9, 5));
      await open(withTarget(8000, reachedFor: reachedFor, reachedOn: reachedOn));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      await type('20000');

      await bloc.dispatch(const BillSheetTargetSaved());

      final RecurringRule saved = recurring.updates.single;
      expect((saved.target, saved.targetReachedFor, saved.targetReachedOn), (Option<Money>.of(Money.fromMajor(20000)), reachedFor, reachedOn));
    });

    test('an unchanged target writes nothing and returns to the sheet', () async {
      await open(withTarget(50000));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      await bloc.dispatch(const BillSheetTargetSaved());

      expect(recurring.updates, isEmpty);
      expect((ready().open, ready().justSaved, ready().changed), (const Option<BillAnswer>.none(), const Option<BillAnswer>.none(), false));
    });

    test('Save at ₹0 does nothing: no write, no haptic, the question stays (F4)', () async {
      await open(WorkedExample.insurance);
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      await bloc.dispatch(const BillSheetTargetSaved());

      expect(recurring.updates, isEmpty);
      expect(haptics.events, isEmpty);
      expect(ready().open, const Option<BillAnswer>.of(BillAnswer.target));
    });

    test('a failed write keeps the question with its digits and saveFailed', () async {
      await open(WorkedExample.insurance);
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      await type('50000');
      recurring.failure = DatabaseFailure('recurring');

      await bloc.dispatch(const BillSheetTargetSaved());

      expect((ready().open, ready().rupees, ready().saveFailed), (const Option<BillAnswer>.of(BillAnswer.target), 50000, true));
      expect(haptics.events.last, 'reject');
    });

    test('a second Save while the first is writing is dropped', () async {
      await open(WorkedExample.insurance);
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      await type('50000');
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;

      bloc.add(const BillSheetTargetSaved());
      await pumpEventQueue();
      expect(ready().saving, isTrue);
      bloc.add(const BillSheetTargetSaved());
      gate.complete();
      await pumpEventQueue();

      expect(recurring.updates, hasLength(1));
    });

    test('Save does nothing outside the question', () async {
      await open(WorkedExample.insurance);

      await bloc.dispatch(const BillSheetTargetSaved());

      expect(recurring.updates, isEmpty);
    });
  });

  group('Clear (AC-T2, E132)', () {
    test('writes the target and both reached columns as none, at once, and returns to the sheet', () async {
      await open(withTarget(
        10000,
        reachedFor: Option<Money>.of(Money.fromMajor(10000)),
        reachedOn: const Option<CalendarDate>.of(WorkedExample.today),
      ));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      await bloc.dispatch(const BillSheetTargetCleared());

      final RecurringRule saved = recurring.updates.single;
      expect((saved.target, saved.targetReachedFor, saved.targetReachedOn), (
        const Option<Money>.none(),
        const Option<Money>.none(),
        const Option<CalendarDate>.none(),
      ));
      expect((ready().open, ready().justSaved), (const Option<BillAnswer>.none(), const Option<BillAnswer>.of(BillAnswer.target)));
      expect(haptics.events.last, 'tick');
    });

    test('does nothing when no target is set', () async {
      await open(WorkedExample.insurance);
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      await bloc.dispatch(const BillSheetTargetCleared());

      expect(recurring.updates, isEmpty);
      expect(ready().open, const Option<BillAnswer>.of(BillAnswer.target));
    });

    test('a failed write keeps the question with saveFailed', () async {
      await open(withTarget(50000));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
      recurring.failure = DatabaseFailure('recurring');

      await bloc.dispatch(const BillSheetTargetCleared());

      expect((ready().open, ready().saveFailed), (const Option<BillAnswer>.of(BillAnswer.target), true));
      expect(haptics.events.last, 'reject');
    });
  });

  group('I bought it (AC-T9, E152)', () {
    test('uses the whole set-aside amount, deletes the saving and closes with BillSheetBought', () async {
      final RecurringRule reached = withTarget(12000);
      await open(reached);

      await bloc.dispatch(const BillSheetBoughtRequested());

      final Entry used = ledger.entries.last;
      expect((used.kind, used.amount, used.savingId), (EntryKind.used, Money.fromMajor(12000), 5));
      expect(recurring.rules.where((RecurringRule r) => r.id == 5), isEmpty);
      expect(recurring.stopped.single.id, 5);
      expect(bloc.state, BillSheetClosed(BillSheetBought(UsedOutcome(entry: used, saving: reached))));
      expect(haptics.events.last, 'tick');
    });

    test('a failed Used write deletes nothing and stays on the sheet with saveFailed', () async {
      await open(withTarget(12000));
      categories.failure = DatabaseFailure('categories');

      await bloc.dispatch(const BillSheetBoughtRequested());

      expect(recurring.stopped, isEmpty);
      expect((ready().saveFailed, ready().saving), (true, false));
      expect(haptics.events.last, 'reject');
    });

    test('a failed delete takes the Used entry back and stays on the sheet with saveFailed', () async {
      final RecurringRule reached = withTarget(12000);
      await open(reached);
      recurring.failure = DatabaseFailure('recurring');

      await bloc.dispatch(const BillSheetBoughtRequested());

      expect(ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
      expect((ready().saveFailed, ready().saving, ready().open), (true, false, const Option<BillAnswer>.none()));
      expect(ready().rule, reached);
      expect(haptics.events.last, 'reject');
    });

    test('when the Used entry cannot be taken back either, it closes with BillSheetUsed so that entry keeps its Undo', () async {
      final RecurringRule reached = withTarget(12000);
      await open(reached);
      recurring.failure = DatabaseFailure('recurring');
      final Completer<void> gate = Completer<void>();
      ledger.nextDeleteGate = gate;

      bloc.add(const BillSheetBoughtRequested());
      await pumpEventQueue();
      final Entry used = ledger.entries.last;
      ledger.failure = DatabaseFailure('ledger');
      gate.complete();
      await pumpEventQueue();

      expect(used.kind, EntryKind.used);
      expect(bloc.state, BillSheetClosed(BillSheetUsed(UsedOutcome(entry: used, saving: reached))));
      expect(haptics.events.last, 'reject');
    });

    test('a second tap while the first is writing is dropped', () async {
      await open(withTarget(12000));
      final Completer<void> gate = Completer<void>();
      ledger.nextAddGate = gate;

      bloc.add(const BillSheetBoughtRequested());
      await pumpEventQueue();
      expect(ready().saving, isTrue);
      bloc.add(const BillSheetBoughtRequested());
      gate.complete();
      await pumpEventQueue();

      expect(ledger.entries.where((Entry e) => e.kind == EntryKind.used), hasLength(1));
    });

    test('does nothing on a bill sheet, which has no UseFromSavings', () async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, withTarget(12000)];
      final FakeClock clock = FakeClock(WorkedExample.now);
      bloc = BillSheetBloc(
        rule: withTarget(12000),
        editBill: EditBill(recurring: recurring, categories: categories, clock: clock),
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
      await pumpEventQueue();

      await bloc.dispatch(const BillSheetBoughtRequested());

      expect(ledger.entries.last.kind, isNot(EntryKind.used));
      expect(ready().today, const Option<CalendarDate>.none());
    });

    test('does nothing while a question is open', () async {
      await open(withTarget(12000));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));

      await bloc.dispatch(const BillSheetBoughtRequested());

      expect(ledger.entries.last.kind, isNot(EntryKind.used));
    });

    test('does nothing before the saving has reached its target', () async {
      await open(withTarget(50000));

      await bloc.dispatch(const BillSheetBoughtRequested());

      expect(ledger.entries.last.kind, isNot(EntryKind.used));
      expect(recurring.stopped, isEmpty);
      expect(bloc.state, isA<BillSheetReady>());
    });

    test('does nothing while Keep saving is writing', () async {
      await open(withTarget(12000));
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;

      bloc.add(const BillSheetKeepSavingRequested());
      await pumpEventQueue();
      expect(ready().saving, isTrue);
      bloc.add(const BillSheetBoughtRequested());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
      expect(recurring.stopped, isEmpty);
    });
  });

  group('Keep saving (AC-T10, E153)', () {
    test('clears the target and both reached columns, flashes the row and stays on the sheet', () async {
      await open(withTarget(
        12000,
        reachedFor: Option<Money>.of(Money.fromMajor(12000)),
        reachedOn: const Option<CalendarDate>.of(WorkedExample.today),
      ));

      await bloc.dispatch(const BillSheetKeepSavingRequested());

      final RecurringRule saved = recurring.updates.single;
      expect((saved.target, saved.targetReachedFor, saved.targetReachedOn), (
        const Option<Money>.none(),
        const Option<Money>.none(),
        const Option<CalendarDate>.none(),
      ));
      expect(saved.nextDue, WorkedExample.insurance.nextDue);
      expect((ready().open, ready().justSaved, ready().changed), (
        const Option<BillAnswer>.none(),
        const Option<BillAnswer>.of(BillAnswer.target),
        true,
      ));
      expect(haptics.events.last, 'tick');
    });

    test('does nothing while a question is open', () async {
      await open(withTarget(12000));
      await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.name));

      await bloc.dispatch(const BillSheetKeepSavingRequested());

      expect(recurring.updates, isEmpty);
    });

    test('does nothing while I bought it is writing', () async {
      await open(withTarget(12000));
      final Completer<void> gate = Completer<void>();
      ledger.nextAddGate = gate;

      bloc.add(const BillSheetBoughtRequested());
      await pumpEventQueue();
      expect(ready().saving, isTrue);
      bloc.add(const BillSheetKeepSavingRequested());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(recurring.updates, isEmpty);
    });
  });
}
