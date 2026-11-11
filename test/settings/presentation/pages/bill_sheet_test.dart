import 'package:hisaab/core/design/hisaab_dimensions.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'dart:ui';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/widgets/keypad.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:hisaab/settings/presentation/pages/bill_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(WorkedExample.entries);
  });

  tearDown(() => recurring.dispose());

  /// Opens the sheet for [rule] over a blank page and returns what it reports when it closes.
  Future<Future<BillSheetOutcome>> open(
    WidgetTester tester, {
    RecurringRule? rule,
    Size size = TestWindows.phone,
    bool reduceMotion = false,
    double textScale = 1,
  }) async {
    final FakeClock clock = FakeClock(WorkedExample.now);
    final BillSheetBloc bloc = await tester.buildBloc(
      () => BillSheetBloc(
        rule: rule ?? WorkedExample.electricity,
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
        haptics: FakeHaptics(),
      ),
    );
    await pumpApp(tester, const Scaffold(), size: size, reduceMotion: reduceMotion, textScale: textScale);
    final Future<BillSheetOutcome> outcome = BillSheet.show(tester.element(find.byType(Scaffold)), bloc);
    await tester.settle();
    return outcome;
  }

  Future<void> tapRow(WidgetTester tester, String answer) async {
    await tester.tap(find.byKey(ValueKey<String>('bill-row-$answer')));
    await tester.settle();
  }

  group('BillSheet: the bill (FR-SE-1 AC-1, AC-2)', () {
    testWidgets('shows the bill with its stamp, four rows and the next date', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      expect(find.text('Bill'), findsOneWidget);
      expect(find.text('Due in 3 days'), findsOneWidget);
      expect(find.bySemanticsLabel('Change Amount, 1,200 rupees'), findsOneWidget);
      expect(find.bySemanticsLabel('Change Day of the month, 29'), findsOneWidget);
      expect(find.bySemanticsLabel('Change Name, Electricity'), findsOneWidget);
      expect(find.bySemanticsLabel('Change Icon, Power'), findsOneWidget);
      expect(find.text('Next due on 29 Oct'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the content starts on the page gutter, like the Add tray', (WidgetTester tester) async {
      await open(tester);
      final double sheet = tester.getTopLeft(find.byType(BillSheet)).dx;
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('bill-slip'))).dx - sheet, HisaabSpacing.gutter);
    });

    testWidgets('a bill shows Amount changes? with its answer (D123)', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('Kind of bill'), findsOneWidget);
      expect(find.text('Same every month'), findsOneWidget);
    });

    testWidgets('a saving has no Amount changes? row', (WidgetTester tester) async {
      await open(tester, rule: WorkedExample.rd);
      expect(find.text('Kind of bill'), findsNothing);
    });

    testWidgets('Amount changes? offers three answers; one tap saves it (D123)', (WidgetTester tester) async {
      await open(tester);
      await tapRow(tester, 'mode');
      expect(find.text('What kind of bill is it?'), findsOneWidget);
      for (final String answer in <String>['fixed', 'varies', 'card']) {
        expect(find.byKey(ValueKey<String>('bill-mode-$answer')), findsOneWidget);
      }
      final double sheet = tester.getTopLeft(find.byType(BillSheet)).dx;
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('bill-mode-fixed'))).dx - sheet, HisaabSpacing.gutter);
      await tester.tap(find.byKey(const ValueKey<String>('bill-mode-varies')));
      await tester.settle();
      expect(recurring.updates.single.amountMode, AmountMode.varies);
      expect(find.text('Changes every month'), findsOneWidget);
      expect(find.text('Changed.'), findsOneWidget);
    });

    testWidgets('a changing bill\'s amount question asks about how much', (WidgetTester tester) async {
      final RecurringRule varies = WorkedExample.electricity.copyWith(amountMode: AmountMode.varies);
      recurring.rules = <RecurringRule>[varies];
      await open(tester, rule: varies);
      await tapRow(tester, 'amount');
      expect(find.text('About how much for Electricity each month?'), findsOneWidget);
    });

    testWidgets('the slip reads as one sentence', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      expect(find.bySemanticsLabel(RegExp(r'^Electricity, Power, 1,200 rupees, every month on day 29, Due in 3 days$')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a bill counted this month says so', (WidgetTester tester) async {
      await open(tester, rule: WorkedExample.rent);
      expect(find.text('Went out 5 Oct'), findsOneWidget);
    });

    testWidgets('the stamp lands with a squash, or only fades with reduced motion', (WidgetTester tester) async {
      await open(tester);
      expect(find.byKey(const ValueKey<String>('bill-stamp-squash')), findsOneWidget);
      Navigator.of(tester.element(find.text('Bill'))).pop();
      await tester.settle();
      await open(tester, reduceMotion: true);
      expect(find.byKey(const ValueKey<String>('bill-stamp-squash')), findsNothing);
      expect(find.text('Due in 3 days'), findsOneWidget);
    });

    testWidgets('Delete bill is a full-width key that closes with the rule (AC-6)', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await open(tester);
      final Finder delete = find.byKey(const ValueKey<String>('bill-delete'));
      expect(tester.getSize(delete).width, tester.getSize(find.byKey(const ValueKey<String>('bill-slip'))).width);
      await tester.tap(delete);
      await tester.settle();
      expect(await outcome, BillSheetDeleted(WorkedExample.electricity));
      expect(find.text('Bill'), findsNothing);
    });

    testWidgets('Back on the bill closes it unchanged (AC-5)', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await open(tester);
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(await outcome, const BillSheetUnchanged());
    });
  });

  group('BillSheet: questions (AC-3, AC-4, AC-7)', () {
    testWidgets('Amount opens the keypad with Save; saving returns to the bill, saying Saved.', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await open(tester);
      await tapRow(tester, 'amount');
      expect(find.byType(Keypad), findsOneWidget);
      for (final String key in '1350'.split('')) {
        await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
        await tester.settle();
      }
      expect(find.text('Was ₹1,200'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('bill-sheet-save')));
      await tester.settle();
      expect(find.byType(Keypad), findsNothing);
      expect(find.text('Changed.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.settle();
      expect(find.text('Changed.'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(await outcome, isA<BillSheetChanged>());
    });

    testWidgets('Back from a question returns to the bill', (WidgetTester tester) async {
      await open(tester);
      await tapRow(tester, 'day');
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(find.text('Bill'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('day-1')), findsNothing);
    });

    testWidgets('the day grid marks the current day; tapping another saves it', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await tapRow(tester, 'day');
      expect(tester.getSemantics(find.byKey(const ValueKey<String>('day-29'))).flagsCollection.isSelected, Tristate.isTrue);
      await tester.tap(find.byKey(const ValueKey<String>('day-20')));
      await tester.settle();
      expect(recurring.updates.single.schedule.anchor.day, 20);
      expect(find.bySemanticsLabel('Change Day of the month, 20'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2400));
      handle.dispose();
    });

    testWidgets('the icon grid shows 16 labelled tiles with the current one picked', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await tapRow(tester, 'icon');
      expect(find.text('From the name: Power'), findsOneWidget);
      for (final BillIcon icon in BillIcon.values) {
        expect(find.byKey(ValueKey<String>('bill-icon-${icon.value}')), findsOneWidget);
      }
      expect(tester.getSemantics(find.byKey(const ValueKey<String>('bill-icon-power'))).flagsCollection.isSelected, Tristate.isTrue);
      expect(find.bySemanticsLabel('TV & apps'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('bill-icon-card')));
      await tester.settle();
      expect(recurring.updates.single.icon.toNullable(), BillIcon.card);
      await tester.pump(const Duration(milliseconds: 2400));
      handle.dispose();
    });

    testWidgets('the name question has no pills and says what the icon will do', (WidgetTester tester) async {
      await open(tester);
      await tapRow(tester, 'name');
      expect(find.text('Icon from the name: Power'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-sheet-name')), 'Gym');
      await tester.settle();
      expect(find.text('No icon matches the name'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-sheet-name')), '  ');
      await tester.settle();
      await tester.tap(find.byKey(const ValueKey<String>('bill-sheet-save')));
      await tester.settle();
      expect(recurring.updates, isEmpty);
    });

    testWidgets('Save and the keyboard\'s Done both save the name', (WidgetTester tester) async {
      await open(tester);
      await tapRow(tester, 'name');
      await tester.enterText(find.byKey(const ValueKey<String>('bill-sheet-name')), 'Bijli');
      await tester.settle();
      await tester.tap(find.byKey(const ValueKey<String>('bill-sheet-save')));
      await tester.settle();
      expect(recurring.updates.last.label, 'Bijli');
      await tapRow(tester, 'name');
      await tester.enterText(find.byKey(const ValueKey<String>('bill-sheet-name')), 'Power');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.settle();
      expect(recurring.updates.last.label, 'Power');
      await tester.pump(const Duration(milliseconds: 2400));
    });

    testWidgets('⌫ on the keypad drops the last digit of the amount', (WidgetTester tester) async {
      await open(tester);
      await tapRow(tester, 'amount');
      await tester.tap(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await tester.settle();
      expect(find.text('Was ₹1,200'), findsOneWidget);
      expect(find.text('₹120'), findsOneWidget);
    });

    testWidgets('a hand-picked icon stays when renaming, and says so', (WidgetTester tester) async {
      await open(tester, rule: WorkedExample.electricity.copyWith(icon: const Option<BillIcon>.of(BillIcon.car)));
      await tapRow(tester, 'name');
      expect(find.text('Icon stays Car. Change it on the bill.'), findsOneWidget);
    });

    testWidgets('a failed save keeps the question open and says so', (WidgetTester tester) async {
      await open(tester);
      await tapRow(tester, 'amount');
      await tester.tap(find.byKey(const ValueKey<String>('keypad-5')));
      await tester.settle();
      recurring.failure = DatabaseFailure('disk full');
      await tester.tap(find.byKey(const ValueKey<String>('bill-sheet-save')));
      await tester.settle();
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);
    });
  });

  group('BillSheet: adaptive (UI_DESIGN §13)', () {
    const List<Size> sizes = <Size>[
      TestWindows.phone,
      TestWindows.phoneLandscape,
      TestWindows.smallPhone,
      TestWindows.foldableUnfolded,
      TestWindows.foldableLandscape,
      TestWindows.tablet,
    ];
    for (final Size size in sizes) {
      for (final String answer in <String>['bill', 'amount', 'mode', 'day', 'name', 'icon']) {
        testWidgets('$answer fits at $size', (WidgetTester tester) async {
          await open(tester, size: size);
          if (answer != 'bill') {
            await tapRow(tester, answer);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('the bill holds at 1.5× text on a small phone', (WidgetTester tester) async {
      await open(tester, size: TestWindows.smallPhone, textScale: 1.5);
      expect(tester.takeException(), isNull);
    });
  });

  group('BillSheet: a saving (D120)', () {
    testWidgets('a saving\'s sheet: eyebrow, 3 rows, stamp, delete', (WidgetTester tester) async {
      ledger.entries.add(Entry(
        id: 50,
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 10, 10),
        createdAt: WorkedExample.now,
        recurringId: WorkedExample.rd.id,
      ));
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      await open(tester, rule: WorkedExample.rd);
      expect(find.text('Saving'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('bill-row-icon')), findsNothing);
      expect(find.byKey(const ValueKey<String>('bill-row-amount')), findsOneWidget);
      expect(find.text('Put in 10 Oct'), findsOneWidget);
      expect(find.text('Next due on 10 Nov'), findsOneWidget);
      expect(find.text('Delete saving'), findsOneWidget);
    });

    testWidgets('a saving\'s name question has no icon line', (WidgetTester tester) async {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      await open(tester, rule: WorkedExample.rd);
      await tapRow(tester, 'name');
      expect(find.text('Every month on day 10'), findsWidgets);
      expect(find.textContaining('icon'), findsNothing);
    });
  });
}
