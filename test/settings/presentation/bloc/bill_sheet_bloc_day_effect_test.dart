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

/// Line 2 of the *Saving up to* slot: what the typed target does to today's share (SPEC BR-23,
/// AC-T3, owner 2026-11-26).
///
/// Insurance moved to the 30th: its ₹1,000 put-in is still due this cycle (4 Oct to 3 Nov), with
/// ₹12,000 set aside; today is 26 Oct 2026.
void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late BillSheetBloc bloc;

  RecurringRule insurance({int? target}) => WorkedExample.insurance.copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 30)),
        nextDue: const CalendarDate(2026, 10, 30),
        target: Option<Money>.fromNullable(target == null ? null : Money.fromMajor(target)),
      );

  Future<void> open(RecurringRule rule, {bool withEffect = true}) async {
    recurring.rules = <RecurringRule>[...WorkedExample.rules, rule];
    final FakeClock clock = FakeClock(WorkedExample.now);
    final GetCycleSummary summary = GetCycleSummary(
      ledger: ledger,
      recurring: recurring,
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: clock,
    );
    bloc = BillSheetBloc(
      rule: rule,
      editBill: EditBill(recurring: recurring, categories: FakeCategoryRepository(), clock: clock),
      getStatus: GetBillStatus(ledger: ledger, clock: clock, summary: summary),
      haptics: FakeHaptics(),
      getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
      getTargetDayEffect: withEffect ? GetTargetDayEffect(summary: summary, ledger: ledger) : null,
      clock: clock,
    );
    await pumpEventQueue();
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
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

  Future<void> openTarget() async {
    await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.target));
    await pumpEventQueue();
  }

  test('a target that cuts the put-in short raises today\'s share', () async {
    await open(insurance());
    await openTarget();

    await type('12500');

    expect(ready().typedDayChange.map((Money change) => change > Money.zero), const Option<bool>.of(true));
  });

  test('a target that lets a cut put-in go in full lowers today\'s share', () async {
    await open(insurance(target: 12500));
    await openTarget();

    await type('20000');

    expect(ready().typedDayChange.map((Money change) => change.isNegative), const Option<bool>.of(true));
  });

  test('a target past this cycle\'s put-in changes nothing', () async {
    await open(insurance());
    await openTarget();

    await type('50000');

    expect(ready().typedDayChange, Option<Money>.of(Money.zero));
  });

  test('the prefilled target changes nothing', () async {
    await open(insurance(target: 12500));
    await openTarget();

    expect(ready().typedDayChange, Option<Money>.of(Money.zero));
  });

  test('nothing typed says nothing', () async {
    await open(insurance());
    await openTarget();

    expect(ready().typedDayChange, const Option<Money>.none());
  });

  test('another question reads no effect', () async {
    await open(insurance());

    await bloc.dispatch(const BillSheetAnswerOpened(BillAnswer.amount));
    await pumpEventQueue();

    expect(ready().dayEffect, const Option<TargetDayEffect>.none());
  });

  test('a sheet without the reader has no effect', () async {
    await open(insurance(), withEffect: false);
    await openTarget();
    await type('12500');

    expect(ready().typedDayChange, const Option<Money>.none());
  });

  test('a failed read leaves the line as it was', () async {
    await open(insurance());
    ledger.failure = const InvalidDataFailure('totals');
    await openTarget();
    ledger.failure = null;
    await type('12500');

    expect(ready().typedDayChange, const Option<Money>.none());
  });
}
