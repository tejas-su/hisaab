import 'package:hisaab/core/widgets/hisaab_chip.dart';
import 'package:hisaab/core/widgets/keypad_key.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/widgets/amount_display.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:hisaab/settings/presentation/bloc/used_bloc.dart';
import 'package:hisaab/settings/presentation/pages/bill_sheet.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pinned_keypad_expectations.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeHaptics haptics;

  setUp(() {
    recurring = FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, WorkedExample.insurance, WorkedExample.rd]);
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
  });

  tearDown(() async {
    await recurring.dispose();
    await ledger.dispose();
  });

  /// Opens a saving's sheet and returns what it reports when it closes.
  Future<Future<BillSheetOutcome>> open(
    WidgetTester tester, {
    RecurringRule? rule,
    Size size = TestWindows.phone,
    double textScale = 1,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) async {
    final FakeClock clock = FakeClock(WorkedExample.now);
    final GetSetAside getSetAside = GetSetAside(recurring: recurring, ledger: ledger);
    final BillSheetBloc bloc = await tester.buildBloc(
      () => BillSheetBloc(
        rule: rule ?? WorkedExample.insurance,
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
        getSetAside: getSetAside,
      ),
    );
    final UsedBloc used = await tester.buildBloc(
      () => UsedBloc(
        getSetAside: getSetAside,
        useFromSavings: UseFromSavings(ledger: ledger, categories: categories, clock: clock),
        haptics: haptics,
      ),
    );
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale, displayFeatures: displayFeatures);
    final Future<BillSheetOutcome> outcome = BillSheet.show(tester.element(find.byType(Scaffold)), bloc, used: used);
    await tester.settle();
    return outcome;
  }

  final Finder usedKey = find.byKey(const ValueKey<String>('bill-used'));
  final Finder saveKey = find.byKey(const ValueKey<String>('used-save'));
  final Finder allChip = find.text('All of it');
  // why: the sheet's handle is a private Material widget, so it is found by its type name.
  final Finder dragHandle = find.byWidgetPredicate((Widget w) => w.runtimeType.toString().contains('DragHandle'));

  // why: the sheet's listener adds the load event inside the fake zone; the bloc answers in its own,
  // so the second settle lets that answer reach the frame.
  Future<void> openQuestion(WidgetTester tester) async {
    await tester.ensureVisible(usedKey);
    await tester.tap(usedKey);
    await tester.settle();
    await tester.settle();
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final String digit in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$digit')));
      await tester.settle();
    }
  }

  String lineOne(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey<String>('used-slot-line-1'))).data!;

  bool saveEnabled(WidgetTester tester) => tester.widget<SignalKey>(saveKey).onPressed != null;

  group('the saving sheet before the question (AC-Y5)', () {
    testWidgets('with ₹12,000 set aside the sheet shows the line and the outlined Used some of it key', (WidgetTester tester) async {
      await open(tester);

      expect(find.text('₹12,000 set aside'), findsOneWidget);
      expect(usedKey, findsOneWidget);
      expect(find.text('Used some of it'), findsOneWidget);
    });

    testWidgets('before the first put-in the sheet has neither the line nor the key', (WidgetTester tester) async {
      ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.saved);

      await open(tester);

      expect(find.textContaining('set aside'), findsNothing);
      expect(usedKey, findsNothing);
    });

    testWidgets('after a full use there is nothing to use, so the key goes', (WidgetTester tester) async {
      ledger.entries.add(Entry(
        id: 900,
        amount: Money.fromMajor(12000),
        kind: EntryKind.used,
        categoryId: SeedCategoryIds.saved,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        savingId: 5,
      ));

      await open(tester);

      expect(usedKey, findsNothing);
    });

    testWidgets('the hint shows on Insurance, School fees and Festival, not on RD', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('Paid the cost from this? Tap Used some of it.'), findsOneWidget);
    });

    for (final String name in <String>['School fees', 'Festival']) {
      testWidgets('the hint shows on $name too', (WidgetTester tester) async {
        final RecurringRule yearly = WorkedExample.insurance.copyWith(label: name);
        recurring.rules = <RecurringRule>[yearly];

        await open(tester, rule: yearly);

        expect(find.text('Paid the cost from this? Tap Used some of it.'), findsOneWidget);
      });
    }

    testWidgets('an RD has the key but not the hint', (WidgetTester tester) async {
      ledger.entries.add(Entry(
        id: 600,
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        recurringId: 4,
      ));

      await open(tester, rule: WorkedExample.rd);

      expect(usedKey, findsOneWidget);
      expect(find.text('Paid the cost from this? Tap Used some of it.'), findsNothing);
    });

    testWidgets('TalkBack reads the key as a button that opens the keypad', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await open(tester);

      final SemanticsNode node = tester.getSemantics(usedKey);
      expect(node.label, 'Used some of it');
      expect(node.hint, 'Opens the keypad.');
      handle.dispose();
    });
  });

  group('the Used question (AC-Y6 to AC-Y9)', () {
    testWidgets('tapping the key opens the question: title, empty amount, pinned keypad, Save off', (WidgetTester tester) async {
      await open(tester);

      await openQuestion(tester);

      expect(find.text('How much did you use from Insurance?'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      expect(find.byKey(const ValueKey<String>('keypad-5')), findsOneWidget);
    });

    testWidgets('All of it fills ₹12,000 and is selected in semantics; a second tap clears it', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await openQuestion(tester);

      await tester.tap(allChip);
      await tester.settle();
      expect(find.text('₹12,000'), findsWidgets);
      expect(tester.getSemantics(allChip).flagsCollection.isSelected, Tristate.isTrue);
      expect(saveEnabled(tester), isTrue);

      await tester.tap(allChip);
      await tester.settle();
      expect(find.text('₹0'), findsOneWidget);
      expect(tester.getSemantics(allChip).flagsCollection.isSelected, isNot(Tristate.isTrue));
      handle.dispose();
    });

    testWidgets('the first key after All of it replaces it', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      await tester.tap(allChip);
      await tester.settle();

      await type(tester, '5');

      expect(find.text('₹5'), findsOneWidget);
    });

    testWidgets('the slot reads the set-aside, then what will stay, and always the same second line', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      expect(lineOne(tester), '₹12,000 is set aside.');

      await type(tester, '4000');
      expect(lineOne(tester), '₹8,000 will still be set aside.');
      expect(find.text("Your daily number doesn't change."), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('keypad-0')));
      await tester.settle();
      expect(find.text("Your daily number doesn't change."), findsOneWidget);
    });

    testWidgets('typing the whole amount reads "Nothing will be set aside."', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);

      await type(tester, '12000');

      expect(lineOne(tester), 'Nothing will be set aside.');
    });

    testWidgets('a digit past ₹12,000 shows the cap line, with the shake and the held ring', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      await type(tester, '1200');

      await type(tester, '1');

      expect(lineOne(tester), "That's all you have set aside. Add the rest as a spend.");
      expect(find.text('₹1,200'), findsWidgets);
      expect(haptics.events.last, 'reject');
      expect(tester.widget<AmountDisplay>(find.byType(AmountDisplay)).rejections, 1);

      await type(tester, '0');
      expect(lineOne(tester), 'Nothing will be set aside.');
    });

    testWidgets('Save closes the sheet and returns BillSheetUsed with the entry', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await open(tester);
      await openQuestion(tester);
      await type(tester, '4000');

      await tester.tap(saveKey);
      await tester.settle();

      expect(find.byType(BillSheet), findsNothing);
      final BillSheetOutcome result = await tester.runAsync(() => outcome) ?? fail('no outcome');
      expect(result, isA<BillSheetUsed>());
      expect((result as BillSheetUsed).outcome.entry.amount, Money.fromMajor(4000));
      expect(result.outcome.saving.label, 'Insurance');
      expect(ledger.entries.last.kind, EntryKind.used);
    });

    testWidgets('Back while Save is writing closes the sheet and the outcome still arrives', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await open(tester);
      await openQuestion(tester);
      await type(tester, '4000');
      final Completer<void> gate = Completer<void>();
      ledger.nextAddGate = gate;
      await tester.tap(saveKey);
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.settle();
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(find.byType(BillSheet), findsNothing);

      gate.complete();
      final BillSheetOutcome result = await tester.runAsync(() => outcome) ?? fail('no outcome');
      expect(result, isA<BillSheetUsed>());
    });

    testWidgets('Back from the question returns to the bill with the digits dropped', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      await type(tester, '4000');

      await tester.binding.handlePopRoute();
      await tester.settle();

      expect(usedKey, findsOneWidget);
      await openQuestion(tester);
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('a failed save keeps the keypad with "Couldn\'t save. Try again."', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      await type(tester, '4000');
      categories.failure = DatabaseFailure('categories');

      await tester.tap(saveKey);
      await tester.settle();

      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('keypad-5')), findsOneWidget);
      expect(find.text('₹4,000'), findsWidgets);
    });

    testWidgets('a failed read of what is set aside offers Try again', (WidgetTester tester) async {
      await open(tester);
      ledger.failure = DatabaseFailure('ledger');
      await openQuestion(tester);
      expect(find.text('Try again'), findsOneWidget);

      ledger.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.settle();
      await tester.settle();

      expect(find.text('How much did you use from Insurance?'), findsOneWidget);
    });

    testWidgets('TalkBack: the slot is a polite live region; All of it is a selected button; the disabled Save has a hint', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await open(tester);
      await openQuestion(tester);

      expect(tester.getSemantics(find.byKey(const ValueKey<String>('used-slot'))).flagsCollection.isLiveRegion, isTrue);
      expect(tester.getSemantics(saveKey).hint, 'Type an amount first.');
      expect(tester.getSemantics(saveKey).flagsCollection.isEnabled, Tristate.isFalse);

      await tester.tap(allChip);
      await tester.settle();
      final SemanticsNode chip = tester.getSemantics(allChip);
      expect(chip.label, 'All of it');
      expect(chip.flagsCollection.isButton, isTrue);
      expect(chip.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });
  });

  group('layout (E111, E113, E115, FR-KS-1)', () {
    final List<PinnedCase> windows = <PinnedCase>[
      ...pinnedCases,
      (name: '412x300 short split-screen', size: TestWindows.splitScreenShort, textScale: 1, bottomInset: 0, features: const <DisplayFeature>[]),
      (name: 'book posture', size: TestWindows.book, textScale: 1, bottomInset: 0, features: const <DisplayFeature>[]),
    ];

    for (final PinnedCase window in windows) {
      testWidgets('the amount, keypad and Save are inside the ${window.name} window', (WidgetTester tester) async {
        setBottomInset(tester, window.bottomInset);
        await open(tester, size: window.size, textScale: window.textScale, displayFeatures: window.features);
        await openQuestion(tester);

        expectPinnedOnScreen(tester, window: window, amount: find.byType(AmountDisplay), action: saveKey);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('at 2.0x text on 320x568 All of it wraps below the amount, nothing overflows and Save is reachable', (WidgetTester tester) async {
      await open(tester, size: TestWindows.smallPhone, textScale: 2);
      await openQuestion(tester);

      expect(tester.getTopLeft(allChip).dy, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AmountDisplay)).dy));
      await tester.ensureVisible(saveKey);
      expect(tester.getRect(saveKey).bottom, lessThanOrEqualTo(TestWindows.smallPhone.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 1.5x text on 320x568 the chip drops below the amount and the keypad stays pinned', (WidgetTester tester) async {
      await open(tester, size: TestWindows.smallPhone, textScale: 1.5);
      await openQuestion(tester);

      expect(tester.getTopLeft(allChip).dy, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AmountDisplay)).dy));
      expect(tester.getRect(saveKey).bottom, lessThanOrEqualTo(TestWindows.smallPhone.height));
    });

    testWidgets('All of it sits beside the amount at 1x text', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);

      expect(tester.getCenter(allChip).dy, closeTo(tester.getCenter(find.byType(AmountDisplay)).dy, 40));
      expect(tester.getTopLeft(allChip).dx, greaterThan(tester.getTopLeft(find.byType(AmountDisplay)).dx));
    });

    testWidgets('the 48dp handle is not drawn under 600dp tall; Back and the scrim still close', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await open(tester, size: TestWindows.smallPhone);
      expect(dragHandle, findsNothing);

      await tester.binding.handlePopRoute();
      await tester.settle();

      expect(find.byType(BillSheet), findsNothing);
      expect(await tester.runAsync(() => outcome), isA<BillSheetUnchanged>());
    });

    testWidgets('the handle is drawn at and above 600dp', (WidgetTester tester) async {
      await open(tester);

      expect(dragHandle, findsOneWidget);
    });
  });
  group('the saving sheet amount question (AC-Y2)', () {
    testWidgets('editing an existing saving shows no yearly caption', (WidgetTester tester) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey<String>('bill-row-amount')));
      await tester.settle();

      expect(find.text('How much do you put in Insurance each month?'), findsOneWidget);
      expect(find.textContaining('divided by 12'), findsNothing);
    });
  });

  group('the Used keypad keys and the slot when nothing is left', () {
    testWidgets('backspace removes a digit and a long press clears the amount', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      await type(tester, '345');

      await tester.tap(find.byType(KeypadKey).last);
      await tester.settle();
      expect(find.text('₹34'), findsOneWidget);

      await tester.longPress(find.byType(KeypadKey).last);
      await tester.settle();
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('when what was set aside fell to nothing behind the sheet the slot says so and Save is off', (WidgetTester tester) async {
      await open(tester);
      await openQuestion(tester);
      await type(tester, '100');
      ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.saved && e.recurringId == 5);

      await tester.tap(saveKey);
      await tester.settle();
      await tester.settle();

      expect(lineOne(tester), 'Nothing is set aside to use.');
      expect(find.byKey(const ValueKey<String>('used-slot-line-2')), findsNothing);
      expect(saveEnabled(tester), isFalse);
      expect(tester.widget<HisaabChip>(find.byType(HisaabChip)).onPressed, isNull);
    });
  });

}
