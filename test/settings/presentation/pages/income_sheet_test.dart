import 'dart:ui';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/core/time/pay_switch.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/widgets/keypad.dart';
import 'package:hisaab/core/widgets/amount_display.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/income_sheet_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/income_sheet_event.dart';
import 'package:hisaab/settings/presentation/pages/income_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../helpers/pump_app.dart';
import '../../../helpers/pinned_keypad_expectations.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late FakeBudgetSettingsRepository settings;
  final FakeClock clock = FakeClock(WorkedExample.now);

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(WorkedExample.entries);
    settings = FakeBudgetSettingsRepository();
  });

  tearDown(() => recurring.dispose());

  Entry pay() => ledger.entries.firstWhere((Entry e) => e.recurringId == WorkedExample.salary.id);

  Income salary() => Income(rule: Option<RecurringRule>.of(WorkedExample.salary), latestPay: Option<Entry>.of(pay()));

  /// Opens the sheet for [income] over a blank page; returns whether it has closed yet.
  Future<bool Function()> open(
    WidgetTester tester, {
    Income? income,
    Size size = TestWindows.phone,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) async {
    final IncomeSheetBloc bloc = await tester.buildBloc(
      () => IncomeSheetBloc(
        income: income ?? salary(),
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
        haptics: FakeHaptics(),
      ),
    );
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale, themeMode: themeMode, displayFeatures: displayFeatures);
    bool closed = false;
    IncomeSheet.show(tester.element(find.byType(Scaffold)), bloc).then((void _) => closed = true).ignore();
    await tester.settle();
    return () => closed;
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.settle();
  }

  Future<void> changeTo(WidgetTester tester, String digits) async {
    await tapKey(tester, const ValueKey<String>('income-row-amount'));
    for (final String key in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
      await tester.pump();
    }
    await tapKey(tester, const ValueKey<String>('income-sheet-save'));
  }

  group('IncomeSheet: the slip (FR-SE-1, D137)', () {
    testWidgets('shows the monthly income, the stamp of the latest pay, two rows and the next payday', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      expect(find.text('Money coming in'), findsOneWidget);
      expect(find.text('Came 4 Oct'), findsOneWidget);
      expect(find.text('Comes every month on day 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Change Amount, 45,000 rupees'), findsOneWidget);
      expect(find.text('Day 4'), findsOneWidget);
      expect(find.text('Next payday 4 Nov'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('reads the slip as one sentence', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      expect(find.bySemanticsLabel('Money coming in, 45,000 rupees, Comes every month on day 4, Came 4 Oct'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a weekly income shows the month and the week it posts', (WidgetTester tester) async {
      final RecurringRule weekly = WorkedExample.salary.copyWith(
        amount: Money.fromMajor(10384),
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
        nextDue: const CalendarDate(2026, 10, 30),
      );
      await open(tester, income: Income(rule: Option<RecurringRule>.of(weekly)));
      expect(find.text('Comes every Friday, about ₹10,384 a week'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Came 4 Oct'), findsNothing);
    });

    testWidgets('a last-day income says so', (WidgetTester tester) async {
      final RecurringRule lastDay = WorkedExample.salary.copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 31), lastDayOfMonth: true),
      );
      await open(tester, income: Income(rule: Option<RecurringRule>.of(lastDay)));
      expect(find.text('Comes on the last day of the month'), findsOneWidget);
      expect(find.text('Last day'), findsOneWidget);
    });

    testWidgets('"It changes" has no amount and says how to add money', (WidgetTester tester) async {
      await open(tester, income: const Income(rule: Option<RecurringRule>.none()));
      expect(find.text('It changes'), findsNWidgets(2));
      expect(find.text('Each month runs from the 1st'), findsOneWidget);
      expect(find.text('Add money when it comes. Tap Add, then Got.'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('income-row-amount')), findsNothing);
    });

    testWidgets('Back on the slip closes the sheet', (WidgetTester tester) async {
      final bool Function() closed = await open(tester);
      await tester.binding.handlePopRoute();
      await tester.settle();
      await tester.pumpAndSettle();
      expect(find.text('Money coming in'), findsNothing);
      expect(closed(), isTrue);
    });
  });

  group('IncomeSheet: changing the amount (FR-SE-1, D137)', () {
    testWidgets('opens onboarding\'s question prefilled, saying when it counts', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-amount'));
      expect(find.text('How much money comes in each month?'), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);
      expect(find.text('From payday, 4 Nov.'), findsOneWidget);
      expect(find.text('This month\'s ₹45,000 stays as it came.'), findsOneWidget);
    });

    testWidgets('typing shows what it was', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-amount'));
      await tester.tap(find.byKey(const ValueKey<String>('keypad-5')));
      await tester.settle();
      expect(find.text('Was ₹45,000'), findsOneWidget);
    });

    testWidgets('with no pay yet only says when it counts', (WidgetTester tester) async {
      await open(tester, income: Income(rule: Option<RecurringRule>.of(WorkedExample.salary)));
      await tapKey(tester, const ValueKey<String>('income-row-amount'));
      expect(find.text('From payday, 4 Nov.'), findsOneWidget);
      expect(find.textContaining('stays as it came'), findsNothing);
    });

    testWidgets('saving returns to the slip, says when it counts and offers this month too', (WidgetTester tester) async {
      await open(tester);
      await changeTo(tester, '50000');
      expect(recurring.rules.first.amount, Money.fromMajor(50000));
      expect(find.byType(Keypad), findsNothing);
      expect(find.text('Changed.'), findsOneWidget);
      expect(find.text('From payday, 4 Nov.'), findsOneWidget);
      expect(find.text('Change this month too'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.settle();
      expect(find.text('Changed.'), findsNothing);
    });

    testWidgets('Change this month too changes the pay, with Undo', (WidgetTester tester) async {
      await open(tester);
      await changeTo(tester, '50000');
      await tapKey(tester, const ValueKey<String>('income-this-month-too'));
      expect(pay().amount, Money.fromMajor(50000));
      expect(find.text('This month\'s pay is now ₹50,000.'), findsOneWidget);
      await tapKey(tester, const ValueKey<String>('income-this-month-undo'));
      expect(pay().amount, Money.fromMajor(45000));
      expect(find.text('Change this month too'), findsOneWidget);
    });

    testWidgets('a failed save keeps the keypad open with the error (AC-7)', (WidgetTester tester) async {
      recurring.failure = DatabaseFailure('boom');
      await open(tester);
      await changeTo(tester, '50000');
      expect(find.byType(Keypad), findsOneWidget);
      expect(find.text('Couldn\'t save. Try again.'), findsOneWidget);
    });

    testWidgets('Back from the amount returns to the slip', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-amount'));
      await tester.binding.handlePopRoute();
      await tester.settle();
      await tester.pumpAndSettle();
      expect(find.byType(Keypad), findsNothing);
      expect(find.text('Next payday 4 Nov'), findsOneWidget);
    });
  });

  group('IncomeSheet: layout and accessibility', () {
    for (final (Size size, double scale) in <(Size, double)>[
      (TestWindows.smallPhone, 2),
      (TestWindows.phoneLandscape, 1),
      (TestWindows.foldableUnfolded, 1),
      (TestWindows.tablet, 1),
    ]) {
      testWidgets('lays out the slip and the amount at $size, $scale× text', (WidgetTester tester) async {
        await open(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        await changeTo(tester, '50000');
        expect(tester.takeException(), isNull);
      });
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('meets the guidelines in $mode', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await open(tester, themeMode: mode);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('IncomeSheet: keypad and closing', () {
    testWidgets('backspace drops a digit and a long press clears', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-amount'));
      await tester.tap(find.bySemanticsLabel(RegExp('Delete last digit')));
      await tester.settle();
      expect(find.text('Was ₹45,000'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel(RegExp('Delete last digit')));
      await tester.settle();
      expect(tester.widget<SignalKey>(find.byKey(const ValueKey<String>('income-sheet-save'))).onPressed, isNull);
    });

    testWidgets('closes when the bloc says so', (WidgetTester tester) async {
      final bool Function() closed = await open(tester);
      tester.element(find.byType(IncomeSheet)).read<IncomeSheetBloc>().add(const IncomeSheetBackPressed());
      await tester.settle();
      await tester.pumpAndSettle();
      expect(closed(), isTrue);
    });

    testWidgets('a salary on a schedule BR-1 has no cycle for reads as "It changes"', (WidgetTester tester) async {
      final RecurringRule biweekly = WorkedExample.salary.copyWith(
        schedule: const Schedule(frequency: Frequency.biweekly, anchor: CalendarDate(2026, 10, 16)),
      );
      await open(tester, income: Income(rule: Option<RecurringRule>.of(biweekly)));
      expect(find.text('Each month runs from the 1st'), findsOneWidget);
      expect(find.text('It changes'), findsOneWidget);
    });
  });

  group('IncomeSheet: when it comes (BR-1a, D140)', () {
    Finder key(String k) => find.byKey(ValueKey<String>(k));

    testWidgets('opens onboarding\'s choices on the current day, with Save off', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      expect(find.text('When does it come?'), findsOneWidget);
      expect(find.text('Day 4'), findsOneWidget);
      expect(tester.widget<SignalKey>(key('income-when-save')).onPressed, isNull);
      expect(key('income-effect'), findsNothing);
    });

    testWidgets('picking day 25 shows how long the money lasts, then Save moves the payday', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-date'));
      expect(find.text('Which day of the month?'), findsOneWidget);
      await tester.tap(find.text('25'));
      await tester.settle();
      expect(find.text('Day 25'), findsOneWidget);
      expect(find.text('This money lasts till 24 Nov.'), findsOneWidget);
      expect(find.text('That\'s 30 days, about ₹281 a day.'), findsOneWidget);
      await tapKey(tester, const ValueKey<String>('income-when-save'));
      expect(settings.settings.paySwitches, const <PaySwitch>[PaySwitch(on: CalendarDate(2026, 10, 26), from: MonthlyOnDay(4))]);
      expect(find.text('Day 25'), findsOneWidget);
      expect(find.text('This money lasts till 24 Nov.'), findsOneWidget);
      expect(find.text('Changed.'), findsOneWidget);
    });

    testWidgets('a weekday picks a weekly payday', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-week'));
      expect(find.text('Which day of the week?'), findsOneWidget);
      await tapKey(tester, const ValueKey<String>('income-weekday-5'));
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('This money lasts till 29 Oct.'), findsOneWidget);
    });

    testWidgets('1st, last day and It changes pick at once', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-first'));
      expect(find.text('This money lasts till 31 Oct.'), findsOneWidget);
      await tapKey(tester, const ValueKey<String>('income-when-last'));
      expect(find.text('This money lasts till 30 Oct.'), findsOneWidget);
      await tapKey(tester, const ValueKey<String>('income-when-changes'));
      await tapKey(tester, const ValueKey<String>('income-when-save'));
      expect(find.text('This money lasts till 31 Oct.'), findsOneWidget);
      expect(find.text('Add money when it comes. Tap Add, then Got.'), findsOneWidget);
    });

    testWidgets('a failed save keeps the choices with the error', (WidgetTester tester) async {
      settings.switchFailure = DatabaseFailure('boom');
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-first'));
      await tapKey(tester, const ValueKey<String>('income-when-save'));
      expect(find.text('When does it come?'), findsOneWidget);
      expect(find.text('Couldn\'t save. Try again.'), findsOneWidget);
    });

    testWidgets('"It changes" to a day asks the amount, showing the new day and its effect', (WidgetTester tester) async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      await open(tester, income: Income(rule: const Option<RecurringRule>.none(), receivedThisMonth: Money.fromMajor(30000)));
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-first'));
      await tapKey(tester, const ValueKey<String>('income-when-save'));
      expect(find.text('How much money comes in each month?'), findsOneWidget);
      expect(find.text('Comes every month on day 1'), findsOneWidget);
      expect(key('income-effect'), findsOneWidget);
      await tapKey(tester, const ValueKey<String>('income-sheet-save'));
      expect(recurring.rules.where((RecurringRule r) => r.isIncomeSource).single.amount, Money.fromMajor(30000));
      expect(find.text('Day 1'), findsOneWidget);
    });

    testWidgets('Back steps out of the day grid, then the choices', (WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-date'));
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(find.text('When does it come?'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.settle();
      await tester.pumpAndSettle();
      expect(find.text('Next payday 4 Nov'), findsOneWidget);
    });

    for (final (Size size, double scale) in <(Size, double)>[(TestWindows.smallPhone, 2), (TestWindows.phoneLandscape, 1), (TestWindows.tablet, 1)]) {
      testWidgets('lays out the choices and the grids at $size, $scale× text', (WidgetTester tester) async {
        await open(tester, size: size, textScale: scale);
        await tapKey(tester, const ValueKey<String>('income-row-when'));
        await tapKey(tester, const ValueKey<String>('income-when-first'));
        expect(tester.takeException(), isNull);
        await tapKey(tester, const ValueKey<String>('income-when-date'));
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.settle();
        await tapKey(tester, const ValueKey<String>('income-when-week'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the choices meet the guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await tapKey(tester, const ValueKey<String>('income-row-when'));
      await tapKey(tester, const ValueKey<String>('income-when-first'));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('IncomeSheet amount question keeps its keypad on screen (P2, P3)', () {
    for (final PinnedCase window in pinnedCases) {
      testWidgets('the amount, keypad and Save are inside the ${window.name} window', (WidgetTester tester) async {
        setBottomInset(tester, window.bottomInset);
        await open(tester, size: window.size, textScale: window.textScale, displayFeatures: window.features);
        await tapKey(tester, const ValueKey<String>('income-row-amount'));
        expectPinnedOnScreen(
          tester,
          window: window,
          amount: find.byType(AmountDisplay),
          action: find.byKey(const ValueKey<String>('income-sheet-save')),
        );
      });
    }
  });
}
