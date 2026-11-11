import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/core/time/pay_switch.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/income_sheet_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/income_sheet_event.dart';
import 'package:hisaab/settings/presentation/bloc/income_sheet_state.dart';
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
  late FakeBudgetSettingsRepository settings;
  late IncomeSheetBloc bloc;

  Entry pay() => ledger.entries.firstWhere((Entry e) => e.recurringId == WorkedExample.salary.id);

  IncomeSheetBloc build(Income income) {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return IncomeSheetBloc(
      income: income,
      changeAmount: ChangeIncomeAmount(recurring: recurring),
      correctPay: CorrectLatestPay(ledger: ledger),
      changeRule: ChangePayRule(recurring: recurring, settings: settings, categories: FakeCategoryRepository(), clock: clock),
      summary: GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: settings,
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      newRuleLabel: 'Money in',
      haptics: haptics,
    );
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(WorkedExample.entries);
    haptics = FakeHaptics();
    settings = FakeBudgetSettingsRepository();
    bloc = build(Income(rule: Option<RecurringRule>.of(WorkedExample.salary), latestPay: Option<Entry>.of(pay())));
  });

  tearDown(() => bloc.close());

  IncomeSheetReady ready() => bloc.state as IncomeSheetReady;

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(IncomeSheetKeyPressed(key));
    }
  }

  Future<void> saveAmount(String digits) async {
    await bloc.dispatch(const IncomeSheetAmountOpened());
    await type(digits);
    await bloc.dispatch(const IncomeSheetAmountSaved());
  }

  group('IncomeSheetBloc', () {
    test('starts on the slip with nothing open or changed', () {
      expect(ready().amountOpen, isFalse);
      expect(ready().changed, isFalse);
      expect(ready().fixable, const Option<Entry>.none());
    });

    test('opening the amount prefills the monthly income, to be replaced by the first key', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      expect(ready().amountOpen, isTrue);
      expect(ready().rupees, 45000);
      await bloc.dispatch(const IncomeSheetKeyPressed('5'));
      expect(ready().rupees, 5);
      expect(haptics.events, <String>['tick']);
    });

    test('backspace and clear edit the typed amount', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await bloc.dispatch(const IncomeSheetBackspacePressed());
      expect(ready().rupees, 4500);
      await bloc.dispatch(const IncomeSheetCleared());
      expect(ready().rupees, 0);
    });

    test('a 10th digit is refused with the reject haptic', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await type('999999999');
      await bloc.dispatch(const IncomeSheetKeyPressed('9'));
      expect(ready().rupees, 999999999);
      expect(ready().rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('keys do nothing while the amount is closed', () async {
      await bloc.dispatch(const IncomeSheetKeyPressed('5'));
      expect(ready().rupees, 0);
      expect(haptics.events, isEmpty);
    });

    test('saving a new amount changes the rule, flashes the row and offers this month too', () async {
      await saveAmount('50000');
      expect(recurring.rules.first.amount, Money.fromMajor(50000));
      expect(ready().amountOpen, isFalse);
      expect(ready().justSaved, isTrue);
      expect(ready().changed, isTrue);
      expect(ready().income.rule.toNullable()?.amount, Money.fromMajor(50000));
      expect(ready().fixable.map((Entry e) => e.id), Option<int>.of(pay().id));
      expect(haptics.events.last, 'tick');
    });

    test('saving the same amount writes nothing and just returns to the slip', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await bloc.dispatch(const IncomeSheetAmountSaved());
      expect(recurring.updates, isEmpty);
      expect(ready().amountOpen, isFalse);
      expect(ready().justSaved, isFalse);
      expect(ready().changed, isFalse);
    });

    test('₹0 is refused with a shake', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await bloc.dispatch(const IncomeSheetCleared());
      await bloc.dispatch(const IncomeSheetAmountSaved());
      expect(ready().amountOpen, isTrue);
      expect(ready().rejections, 1);
      expect(recurring.updates, isEmpty);
    });

    test('a failed save keeps the keypad open with the error (AC-7)', () async {
      recurring.failure = DatabaseFailure('boom');
      await saveAmount('50000');
      expect(ready().amountOpen, isTrue);
      expect(ready().saveFailed, isTrue);
      expect(haptics.events.last, 'reject');
    });

    test('a pay already changed by hand is not offered', () async {
      final Entry edited = Entry(
        id: pay().id,
        amount: Money.fromMajor(47000),
        kind: pay().kind,
        categoryId: pay().categoryId,
        date: pay().date,
        createdAt: pay().createdAt,
        recurringId: pay().recurringId,
      );
      await bloc.close();
      bloc = build(Income(rule: Option<RecurringRule>.of(WorkedExample.salary), latestPay: Option<Entry>.of(edited)));
      await saveAmount('50000');
      expect(ready().fixable, const Option<Entry>.none());
    });

    test('no pay posted yet offers nothing', () async {
      await bloc.close();
      bloc = build(Income(rule: Option<RecurringRule>.of(WorkedExample.salary)));
      await saveAmount('50000');
      expect(ready().fixable, const Option<Entry>.none());
    });

    test('a second change keeps the offer, and changing back to the pay withdraws it', () async {
      await saveAmount('50000');
      await saveAmount('55000');
      expect(ready().fixable.isSome(), isTrue);
      await saveAmount('45000');
      expect(ready().fixable, const Option<Entry>.none());
    });

    test('Change this month too sets the pay to the new amount, with Undo', () async {
      await saveAmount('50000');
      await bloc.dispatch(const IncomeSheetThisMonthChanged());
      expect(pay().amount, Money.fromMajor(50000));
      expect(ready().fixable, const Option<Entry>.none());
      expect(ready().corrected.map((Entry e) => e.amount), Option<Money>.of(Money.fromMajor(45000)));
      expect(haptics.events.last, 'success');
      await bloc.dispatch(const IncomeSheetThisMonthUndone());
      expect(pay().amount, Money.fromMajor(45000));
      expect(ready().corrected, const Option<Entry>.none());
      expect(ready().fixable.isSome(), isTrue);
    });

    test('a failed Change this month too keeps the offer and shows the error', () async {
      await saveAmount('50000');
      ledger.failure = DatabaseFailure('boom');
      await bloc.dispatch(const IncomeSheetThisMonthChanged());
      expect(ready().fixable.isSome(), isTrue);
      expect(ready().saveFailed, isTrue);
    });

    test('a failed Undo keeps the change and shows the error', () async {
      await saveAmount('50000');
      await bloc.dispatch(const IncomeSheetThisMonthChanged());
      ledger.failure = DatabaseFailure('boom');
      await bloc.dispatch(const IncomeSheetThisMonthUndone());
      expect(ready().corrected.isSome(), isTrue);
      expect(ready().saveFailed, isTrue);
    });

    test('Change this month too and Undo do nothing when not offered', () async {
      await bloc.dispatch(const IncomeSheetThisMonthChanged());
      await bloc.dispatch(const IncomeSheetThisMonthUndone());
      expect(ledger.saved, isEmpty);
    });

    test('the "Changed." note expires', () async {
      await saveAmount('50000');
      await bloc.dispatch(const IncomeSheetSavedNoteExpired());
      expect(ready().justSaved, isFalse);
    });

    test('Back closes the question, then the sheet', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await bloc.dispatch(const IncomeSheetBackPressed());
      expect(ready().amountOpen, isFalse);
      await bloc.dispatch(const IncomeSheetBackPressed());
      expect(bloc.state, const IncomeSheetClosed());
    });

    test('"It changes" has no amount to open', () async {
      await bloc.close();
      bloc = build(const Income(rule: Option<RecurringRule>.none()));
      await bloc.dispatch(const IncomeSheetAmountOpened());
      expect(ready().amountOpen, isFalse);
      await bloc.dispatch(const IncomeSheetAmountSaved());
      expect(recurring.updates, isEmpty);
    });

    test('a second Save while the first is writing saves once (droppable)', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await type('50000');
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;
      bloc
        ..add(const IncomeSheetAmountSaved())
        ..add(const IncomeSheetAmountSaved());
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await bloc.dispatch(const IncomeSheetSavedNoteExpired());
      expect(recurring.updates, hasLength(1));
    });

    test('closing mid-save doesn\'t throw', () async {
      await bloc.dispatch(const IncomeSheetAmountOpened());
      bloc.add(const IncomeSheetAmountSaved());
      await expectLater(bloc.close(), completes);
    });
  });

  group('IncomeSheet events and states', () {
    test('compare by their fields', () {
      expect(const IncomeSheetKeyPressed('1'), const IncomeSheetKeyPressed('1'));
      expect(const IncomeSheetKeyPressed('1'), isNot(const IncomeSheetKeyPressed('2')));
      expect(const IncomeSheetAmountOpened(), const IncomeSheetAmountOpened());
      expect(const IncomeSheetClosed(), const IncomeSheetClosed());
      // why: const instances are identical, so == never reads props; hashCode always does.
      expect(const IncomeSheetAmountOpened().hashCode, const IncomeSheetAmountOpened().hashCode);
      expect(const IncomeSheetClosed().hashCode, const IncomeSheetClosed().hashCode);
      expect(
        IncomeSheetReady(income: Income(rule: Option<RecurringRule>.of(WorkedExample.salary)), rupees: 5),
        IncomeSheetReady(income: Income(rule: Option<RecurringRule>.of(WorkedExample.salary)), rupees: 5),
      );
    });
  });

  group('IncomeSheetBloc — when it comes (BR-1a, D140)', () {
    Future<void> choose(PayRule rule) async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      await bloc.dispatch(IncomeSheetPayRuleChosen(rule));
    }

    test('opens on the current rule, with nothing to save', () async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.choices));
      expect(ready().draft, const Option<PayRule>.of(MonthlyOnDay(4)));
      expect(ready().preview, const Option<CycleSummary>.none());
    });

    test('the day and weekday grids open from the choices and pick back into them', () async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      await bloc.dispatch(const IncomeSheetDayGridOpened());
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.day));
      await bloc.dispatch(const IncomeSheetPayRuleChosen(MonthlyOnDay(25)));
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.choices));
      await bloc.dispatch(const IncomeSheetWeekdayGridOpened());
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.weekday));
    });

    test('picking a new day previews how long the money lasts, before saving', () async {
      await choose(const MonthlyOnDay(25));
      expect(ready().draft, const Option<PayRule>.of(MonthlyOnDay(25)));
      expect(ready().preview.map((CycleSummary s) => s.cycle.end), const Option<CalendarDate>.of(CalendarDate(2026, 11, 24)));
      expect(ready().preview.map((CycleSummary s) => s.todayShare), Option<Money>.of(Money.fromMajor(281)));
      expect(settings.settings.paySwitches, isEmpty);
    });

    test('picking the current rule again clears the preview', () async {
      await choose(const MonthlyOnDay(25));
      await bloc.dispatch(const IncomeSheetPayRuleChosen(MonthlyOnDay(4)));
      expect(ready().preview, const Option<CycleSummary>.none());
    });

    test('saving records the switch, moves the salary and says how long the money lasts', () async {
      await choose(const MonthlyOnDay(25));
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      expect(settings.settings.paySwitches, const <PaySwitch>[PaySwitch(on: CalendarDate(2026, 10, 26), from: MonthlyOnDay(4))]);
      expect(ready().income.rule.toNullable()?.nextDue, const CalendarDate(2026, 11, 25));
      expect(ready().step, const Option<IncomeWhenStep>.none());
      expect(ready().justSaved, isTrue);
      expect(ready().changed, isTrue);
      expect(ready().lastsTill, const Option<CalendarDate>.of(CalendarDate(2026, 11, 24)));
      expect(haptics.events.last, 'tick');
    });

    test('a later amount change drops the lasts-till note', () async {
      await choose(const MonthlyOnDay(25));
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      await saveAmount('50000');
      expect(ready().lastsTill, const Option<CalendarDate>.none());
    });

    test('saving the current rule does nothing', () async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      expect(settings.settings.paySwitches, isEmpty);
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.choices));
    });

    test('to "It changes" stops the salary', () async {
      await choose(const IrregularIncome());
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      expect(ready().income.rule, const Option<RecurringRule>.none());
      expect(ready().lastsTill, const Option<CalendarDate>.of(CalendarDate(2026, 10, 31)));
    });

    test('a failed save keeps the question open with the error', () async {
      await choose(const MonthlyOnDay(25));
      settings.switchFailure = DatabaseFailure('boom');
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.choices));
      expect(ready().saveFailed, isTrue);
    });

    test('"It changes" to a day asks the amount, prefilled with this month, then saves both', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      await bloc.close();
      bloc = build(Income(rule: const Option<RecurringRule>.none(), receivedThisMonth: Money.fromMajor(30000)));
      await choose(const MonthlyOnDay(1));
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      expect(ready().amountOpen, isTrue);
      expect(ready().pendingRule, const Option<PayRule>.of(MonthlyOnDay(1)));
      expect(ready().rupees, 30000);
      expect(settings.settings.paySwitches, isEmpty);
      await bloc.dispatch(const IncomeSheetAmountSaved());
      expect(ready().amountOpen, isFalse);
      expect(ready().income.rule.toNullable()?.amount, Money.fromMajor(30000));
      expect(settings.settings.paySwitches.single.from, const IrregularIncome());
    });

    test('a failed new-rule save keeps the amount open with the error', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      await bloc.close();
      bloc = build(Income(rule: const Option<RecurringRule>.none(), receivedThisMonth: Money.fromMajor(30000)));
      await choose(const MonthlyOnDay(1));
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      settings.switchFailure = DatabaseFailure('boom');
      await bloc.dispatch(const IncomeSheetAmountSaved());
      expect(ready().amountOpen, isTrue);
      expect(ready().saveFailed, isTrue);
    });

    test('Back steps out one level at a time', () async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      await bloc.dispatch(const IncomeSheetDayGridOpened());
      await bloc.dispatch(const IncomeSheetBackPressed());
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.choices));
      await bloc.dispatch(const IncomeSheetBackPressed());
      expect(ready().step, const Option<IncomeWhenStep>.none());
      expect(ready().draft, const Option<PayRule>.none());
    });

    test('Back from the new amount returns to the choices', () async {
      await bloc.close();
      bloc = build(const Income(rule: Option<RecurringRule>.none()));
      await choose(const MonthlyOnDay(1));
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      await bloc.dispatch(const IncomeSheetBackPressed());
      expect(ready().amountOpen, isFalse);
      expect(ready().pendingRule, const Option<PayRule>.none());
      expect(ready().step, const Option<IncomeWhenStep>.of(IncomeWhenStep.choices));
    });

    test('the questions do nothing when not open', () async {
      await bloc.dispatch(const IncomeSheetDayGridOpened());
      await bloc.dispatch(const IncomeSheetWeekdayGridOpened());
      await bloc.dispatch(const IncomeSheetPayRuleChosen(MonthlyOnDay(25)));
      await bloc.dispatch(const IncomeSheetPayRuleSaved());
      expect(ready().step, const Option<IncomeWhenStep>.none());
      await bloc.dispatch(const IncomeSheetAmountOpened());
      await bloc.dispatch(const IncomeSheetWhenOpened());
      expect(ready().step, const Option<IncomeWhenStep>.none());
    });

    test('a newer pick\'s preview wins over an older, slower one (restartable)', () async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      final Completer<void> gate = Completer<void>();
      ledger.nextReadGate = gate;
      bloc.add(const IncomeSheetPayRuleChosen(MonthlyOnDay(25)));
      await Future<void>.delayed(Duration.zero);
      await bloc.dispatch(const IncomeSheetPayRuleChosen(MonthlyOnDay(1)));
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(ready().preview.map((CycleSummary s) => s.cycle.end), const Option<CalendarDate>.of(CalendarDate(2026, 10, 31)));
    });

    test('a failed preview shows no effect', () async {
      await bloc.dispatch(const IncomeSheetWhenOpened());
      settings.failure = DatabaseFailure('boom');
      await bloc.dispatch(const IncomeSheetPayRuleChosen(MonthlyOnDay(25)));
      expect(ready().preview, const Option<CycleSummary>.none());
      expect(ready().draft, const Option<PayRule>.of(MonthlyOnDay(25)));
    });

    test('events compare by their fields', () {
      expect(const IncomeSheetPayRuleChosen(MonthlyOnDay(1)), const IncomeSheetPayRuleChosen(MonthlyOnDay(1)));
      expect(const IncomeSheetPayRuleChosen(MonthlyOnDay(1)), isNot(const IncomeSheetPayRuleChosen(MonthlyOnDay(2))));
    });
  });
}
