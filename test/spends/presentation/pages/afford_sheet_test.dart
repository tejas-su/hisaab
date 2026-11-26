import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/design/hisaab_dimensions.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_host.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/saving_started.dart';
import 'package:hisaab/spends/domain/usecase/get_afford_inputs.dart';
import 'package:hisaab/spends/domain/usecase/start_saving_for.dart';
import 'package:hisaab/spends/domain/usecase/undo_start_saving.dart';
import 'package:hisaab/spends/presentation/bloc/afford_bloc.dart';
import 'package:hisaab/spends/presentation/bloc/afford_undo_bloc.dart';
import 'package:hisaab/spends/presentation/bloc/afford_undo_event.dart';
import 'package:hisaab/spends/presentation/pages/afford_sheet.dart';
import 'package:hisaab/spends/presentation/widgets/afford/afford_rise_in.dart';
import 'package:hisaab/spends/presentation/widgets/afford/afford_undo_listener.dart';
import 'package:hisaab/spends/presentation/widgets/afford/afford_verdict_block.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/spends/afford_book.dart';
import '../../../helpers/pump_app.dart';

const String _nbsp = ' ';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;

  setUp(() {
    ledger = FakeLedgerRepository(AffordBook.history());
    recurring = FakeRecurringRepository(AffordBook.rules(), ledger);
  });

  tearDown(() => ledger.dispose());

  Future<void> open(
    WidgetTester tester, {
    Size size = TestWindows.phone,
    double textScale = 1,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) async {
    final FakeClock clock = FakeClock(AffordBook.now);
    final FakeCategoryRepository categories = FakeCategoryRepository();
    final AffordBloc bloc = await tester.buildBloc(
      () => AffordBloc(
        getInputs: GetAffordInputs(
          ledger: ledger,
          recurring: recurring,
          settings: FakeBudgetSettingsRepository(),
          periods: const PeriodCalculator(),
          clock: clock,
        ),
        startSaving: StartSavingFor(
          addBill: AddBill(recurring: recurring, categories: categories, clock: clock),
          editBill: EditBill(recurring: recurring, categories: categories, clock: clock),
          recurring: recurring,
        ),
        clock: clock,
        haptics: FakeHaptics(),
      ),
    );
    final AffordUndoBloc undo = await tester.buildBloc(
      () => AffordUndoBloc(
        undo: UndoStartSaving(recurring: recurring),
        haptics: FakeHaptics(),
      ),
    );
    addTearDown(undo.close);
    await pumpApp(
      tester,
      Scaffold(
        body: HisaabSnackbarHost(
          child: BlocProvider<AffordUndoBloc>.value(
            value: undo,
            child: AffordUndoListener(child: Builder(builder: (BuildContext _) => const SizedBox.expand(key: ValueKey<String>('spends')))),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      displayFeatures: displayFeatures,
    );
    AffordSheet.show(tester.element(find.byKey(const ValueKey<String>('spends'))), bloc)
        .then((Option<SavingStarted> started) => started.map((SavingStarted s) => undo.add(AffordUndoOffered(s))))
        .ignore();
    await tester.settle();
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final String key in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
      await tester.settle();
    }
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey<String>(key)));
    await tester.tap(find.byKey(ValueKey<String>(key)));
    await tester.settle();
  }

  Future<void> item(WidgetTester tester, {String name = 'Mac', String price = '127000'}) async {
    await tester.enterText(find.byKey(const ValueKey<String>('afford-name')), name);
    await tester.settle();
    await keys(tester, price);
    await tapKey(tester, 'afford-next');
  }

  Future<void> answer(WidgetTester tester, {String have = '60000', String price = '127000'}) async {
    await item(tester, price: price);
    await tapKey(tester, 'afford-yes');
    await keys(tester, have);
    await tapKey(tester, 'afford-see-answer');
  }

  void useCardBook() {
    recurring.rules = AffordBook.rules(income: 120000, bills: 25000);
    ledger.entries
      ..clear()
      ..addAll(AffordBook.history(usual: 2000));
  }

  group('AffordSheet steps (FR-SP-9 AC-2, AC-3)', () {
    testWidgets('step 1 asks what and how much; Next is grey until both are there', (WidgetTester tester) async {
      await open(tester);

      expect(find.text('Can I afford it?'), findsOneWidget);
      expect(find.text('What do you want to buy?'), findsOneWidget);
      expect(find.text('How much it costs'), findsOneWidget);
      expect(tester.widget<SignalKey>(find.byKey(const ValueKey<String>('afford-next'))).onPressed, isNull);
    });

    testWidgets('step 2 names the item and its price and offers Nothing yet and Yes', (WidgetTester tester) async {
      await open(tester);
      await item(tester);

      expect(find.text('Mac$_nbsp· ₹1,27,000'), findsOneWidget);
      expect(find.text('Saved anything for it already?'), findsOneWidget);
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('keypad-5')), findsNothing);

      await tapKey(tester, 'afford-yes');
      expect(find.text("Money you've put away for this, in any account"), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('keypad-5')), findsOneWidget);
    });

    testWidgets('Nothing yet hides the keypad again', (WidgetTester tester) async {
      await open(tester);
      await item(tester);
      await tapKey(tester, 'afford-yes');
      await tapKey(tester, 'afford-nothing-yet');

      expect(find.byKey(const ValueKey<String>('keypad-5')), findsNothing);
    });

    testWidgets('Escape steps back like Back', (WidgetTester tester) async {
      await open(tester);
      await item(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.settle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.settle();

      expect(find.text('What do you want to buy?'), findsOneWidget);
    });

    testWidgets('the sheet holds its place while the answer loads', (WidgetTester tester) async {
      await open(tester);
      await item(tester);
      final Completer<void> gate = Completer<void>();
      recurring.nextReadGate = gate;

      await tapKey(tester, 'afford-see-answer');
      expect(find.text('Mac$_nbsp· ₹1,27,000'), findsOneWidget);
      expect(find.text('Not yet.'), findsNothing);

      gate.complete();
      await tester.settle();
      expect(find.text('Not yet.'), findsOneWidget);
    });

    testWidgets('⌫ and long-press clear reach the bloc', (WidgetTester tester) async {
      await open(tester);
      await keys(tester, '50');
      await tester.tap(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await tester.settle();
      expect(find.text('₹5'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await tester.settle();
      expect(find.text('₹5'), findsNothing);
    });

    testWidgets('Back steps back from the answer to step 2 to step 1, then closes', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);

      await tester.tap(find.byKey(const ValueKey<String>('back-well')));
      await tester.settle();
      expect(find.text('Saved anything for it already?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('back-well')));
      await tester.settle();
      expect(find.text('What do you want to buy?'), findsOneWidget);
      expect(find.text('₹1,27,000'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('back-well')));
      await tester.settle();
      expect(find.byType(AffordSheet), findsNothing);
    });
  });

  group('AffordSheet answers (AC-4)', () {
    testWidgets('Not yet: save spare a month, done by Dec 2027, and the day amounts', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);

      expect(find.text('Not yet.'), findsOneWidget);
      expect(find.text("Save ₹5,000 a month and it's yours by Dec 2027."), findsOneWidget);
      expect(find.text("That's about ₹900 a day for now, instead of ₹1,066."), findsOneWidget);
    });

    testWidgets('Yes, you can: pay it from what is saved, with a quiet Okay that closes', (WidgetTester tester) async {
      await open(tester);
      await answer(tester, have: '127000');

      expect(find.text('Yes, you can.'), findsOneWidget);
      expect(find.text("Pay it from the ₹1,27,000 you've saved."), findsOneWidget);
      expect(find.byType(SignalKey), findsNothing);

      await tapKey(tester, 'afford-okay');
      expect(find.byType(AffordSheet), findsNothing);
    });

    testWidgets('Yes, without a loan: the card part is added when the card bill is paid', (WidgetTester tester) async {
      useCardBook();
      await open(tester);
      await answer(tester, have: '110000');

      expect(find.text('Yes, without a loan.'), findsOneWidget);
      expect(
        find.text('Use your ₹1,10,000 and put ₹17,000 on the card. Add ₹17,000 when you pay the card bill.'),
        findsOneWidget,
      );
      expect(find.text('Your days stay at about ₹2,600.'), findsOneWidget);
    });

    testWidgets('Yes, without a loan with nothing saved puts it all on the card', (WidgetTester tester) async {
      useCardBook();
      await open(tester);
      await item(tester, price: '17000');
      await tapKey(tester, 'afford-see-answer');

      expect(find.text('Put ₹17,000 on the card. Add ₹17,000 when you pay the card bill.'), findsOneWidget);
    });

    testWidgets('days full: Not yet, your usual days already use your monthly money', (WidgetTester tester) async {
      ledger.entries
        ..clear()
        ..addAll(AffordBook.history(usual: 1000));
      await open(tester);
      await answer(tester);

      expect(find.text('Not yet.'), findsOneWidget);
      expect(find.text('Your usual days already use your monthly money.'), findsOneWidget);
      expect(find.byType(SignalKey), findsNothing);
      expect(find.byKey(const ValueKey<String>('afford-okay')), findsOneWidget);
    });

    testWidgets('no history: Ask again after payday, with no bars and a quiet Okay', (WidgetTester tester) async {
      ledger.entries.clear();
      await open(tester);
      await answer(tester);

      expect(find.text('Ask again after payday.'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('afford-floor-tick')), findsNothing);
      expect(find.byKey(const ValueKey<String>('afford-okay')), findsOneWidget);
    });

    testWidgets('the answer rises in, with the action pinned outside it (UI_DESIGN 5.4a)', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);

      expect(find.descendant(of: find.byType(AffordRiseIn), matching: find.byType(AffordVerdictBlock)), findsOneWidget);
      expect(find.descendant(of: find.byType(AffordRiseIn), matching: find.byKey(const ValueKey<String>('afford-start-saving'))), findsNothing);
    });

    testWidgets('only the Start saving key is marigold on a Not yet answer', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);

      expect(find.byType(SignalKey), findsOneWidget);
      expect(tester.widget<SignalKey>(find.byType(SignalKey)).label, 'Start saving ₹5,000 a month');
      expect(find.byKey(const ValueKey<String>('afford-okay')), findsNothing);
    });

    testWidgets('the bars carry the floor tick and the breathing-space line', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);

      expect(find.byKey(const ValueKey<String>('afford-floor-tick')), findsNWidgets(2));
      expect(find.text('Usually'), findsOneWidget);
      expect(find.text('With this buy'), findsOneWidget);
      expect(find.text('The line is your breathing space: usual ₹750 a day + 20%.'), findsOneWidget);
    });

    testWidgets('a failed read says so', (WidgetTester tester) async {
      await open(tester);
      await item(tester);
      recurring.failure = DatabaseFailure('x');
      await tapKey(tester, 'afford-see-answer');

      expect(find.text("Couldn't open this."), findsOneWidget);
    });
  });

  group('AffordSheet Other ways (AC-5)', () {
    testWidgets('toggles three rows and marks the suggested one', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);
      expect(find.text('From savings'), findsNothing);

      await tapKey(tester, 'afford-other-ways');

      expect(find.text('From savings'), findsOneWidget);
      expect(find.text('₹60,000 saved. Short by ₹67,000.'), findsOneWidget);
      expect(find.text('Savings, then the card'), findsOneWidget);
      expect(find.text('₹67,000 on the card would leave less than your ₹900 a day.'), findsOneWidget);
      expect(find.text('Save up$_nbsp· suggested'), findsOneWidget);
      expect(find.text('₹5,000 a month, ready by Dec 2027.'), findsOneWidget);

      await tapKey(tester, 'afford-other-ways');
      expect(find.text('From savings'), findsNothing);
    });

    testWidgets('the card row fits, and the other rows say not needed, on a covered buy', (WidgetTester tester) async {
      useCardBook();
      await open(tester);
      await answer(tester, have: '110000');
      await tapKey(tester, 'afford-other-ways');

      expect(find.text('Savings, then the card$_nbsp· suggested'), findsOneWidget);
      expect(find.text('₹17,000 on the card. After payday about ₹2,600 a day.'), findsOneWidget);
      expect(find.text('₹23,000 a month, ready by Nov 2026.'), findsOneWidget);
    });

    testWidgets('Yes, you can marks From savings and the others are not needed', (WidgetTester tester) async {
      await open(tester);
      await answer(tester, have: '127000');
      await tapKey(tester, 'afford-other-ways');

      expect(find.text('From savings$_nbsp· suggested'), findsOneWidget);
      expect(find.text('Covered. ₹1,27,000 saved for it.'), findsOneWidget);
      expect(find.text('Not needed.'), findsNWidgets(2));
    });

    testWidgets('nothing saved and nothing spare read as such', (WidgetTester tester) async {
      ledger.entries
        ..clear()
        ..addAll(AffordBook.history(usual: 1000));
      await open(tester);
      await item(tester);
      await tapKey(tester, 'afford-see-answer');
      await tapKey(tester, 'afford-other-ways');

      expect(find.text('Nothing saved yet. Short by ₹1,27,000.'), findsOneWidget);
      expect(find.text('Nothing spare after your usual days.'), findsOneWidget);
    });

    testWidgets('with no history the card and Save up rows are not available yet', (WidgetTester tester) async {
      ledger.entries.clear();
      await open(tester);
      await answer(tester);
      await tapKey(tester, 'afford-other-ways');

      expect(find.text('Not available yet.'), findsNWidgets(2));
    });

    testWidgets('past 120 put-ins it says over 10 years to go', (WidgetTester tester) async {
      recurring.rules = AffordBook.rules(income: 40500);
      await open(tester);
      await answer(tester);
      await tapKey(tester, 'afford-other-ways');

      expect(find.text('Save ₹500 a month. It would take over 10 years.'), findsOneWidget);
      expect(find.text('₹500 a month, over 10 years to go.'), findsOneWidget);
    });
  });

  group('AffordSheet Start saving and Undo (AC-6, E164)', () {
    testWidgets('Start saving closes the sheet and Undo deletes the new saving', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);

      await tapKey(tester, 'afford-start-saving');
      await tester.settle();

      expect(find.byType(AffordSheet), findsNothing);
      expect(find.text('Saving ₹5,000 a month for Mac'), findsOneWidget);
      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), hasLength(1));

      await tester.tap(find.text('Undo'));
      await tester.settle();

      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), isEmpty);
    });

    testWidgets('Undo on a re-check puts the old amount and target back', (WidgetTester tester) async {
      final RecurringRule before = AffordBook.mac(target: Option<Money>.of(Money.fromMajor(90000))).copyWith(amount: Money.fromMajor(3000));
      recurring.rules = <RecurringRule>[...AffordBook.rules(), before];
      await open(tester);
      await answer(tester);

      await tapKey(tester, 'afford-start-saving');
      await tester.settle();
      final RecurringRule changed = recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId);
      expect(changed.amount, Money.fromMajor(5000));
      expect(changed.target, Option<Money>.of(Money.fromMajor(67000)));

      await tester.tap(find.text('Undo'));
      await tester.settle();

      final RecurringRule restored = recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId);
      expect(restored.amount, Money.fromMajor(3000));
      expect(restored.target, Option<Money>.of(Money.fromMajor(90000)));
    });

    testWidgets("a failed Undo says it couldn't save and keeps the saving (E164)", (WidgetTester tester) async {
      await open(tester);
      await answer(tester);
      await tapKey(tester, 'afford-start-saving');
      await tester.settle();
      ledger.failure = DatabaseFailure('x');

      await tester.tap(find.text('Undo'));
      await tester.settle();

      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), hasLength(1));
    });

    testWidgets('a failed save keeps the answer and says so', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);
      recurring.failure = DatabaseFailure('x');

      await tapKey(tester, 'afford-start-saving');

      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.byType(AffordSheet), findsOneWidget);
    });
  });

  group('AffordSheet TalkBack (AC-9)', () {
    testWidgets('announces the verdict and its sentences once when the answer appears', (WidgetTester tester) async {
      await open(tester);
      await answer(tester);
      await tapKey(tester, 'afford-other-ways');

      expect(
        tester.takeAnnouncements().map((CapturedAccessibilityAnnouncement a) => a.message),
        <String>[
          "Not yet. Save 5,000 rupees a month and it's yours by December 2027. "
              "That's about 900 rupees a day for now, instead of 1,066 rupees.",
        ],
      );
    });

    testWidgets('reads the verdict and its sentences as one node with amounts spoken', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await answer(tester);

      expect(
        find.bySemanticsLabel(
          "Not yet. Save 5,000 rupees a month and it's yours by December 2027. "
          "That's about 900 rupees a day for now, instead of 1,066 rupees.",
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Usually, 1,066 rupees a day'), findsOneWidget);
      expect(find.bySemanticsLabel('Mac, 1,27,000 rupees'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AffordSheet layer (UI_DESIGN §3, D100)', () {
    testWidgets('the sheet is raised on surface, so it stands off the page behind it', (WidgetTester tester) async {
      await open(tester);

      expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor, HisaabColors.light.surface);
    });

    testWidgets('the name field and the Back well fill hairline on the surface sheet', (WidgetTester tester) async {
      await open(tester);

      final BuildContext field = tester.element(find.byKey(const ValueKey<String>('afford-name')));
      expect(Theme.of(field).inputDecorationTheme.fillColor, HisaabColors.light.hairline);
      final ShapeDecoration well = tester.widget<Container>(find.byKey(const ValueKey<String>('back-well'))).decoration! as ShapeDecoration;
      expect(well.color, HisaabColors.light.hairline);
    });

    testWidgets('the shopping glyph in the name field draws at the icon size, not the 48dp slot', (WidgetTester tester) async {
      await open(tester);

      final Finder glyph = find.descendant(of: find.byKey(const ValueKey<String>('afford-name')), matching: find.byType(HugeIcon));
      expect(tester.getSize(glyph), const Size.square(HisaabSizes.iconSize));
    });
  });

  group('AffordSheet layout (AC-8)', () {
    final List<({String name, Size size, double textScale, List<DisplayFeature> features})> windows =
        <({String name, Size size, double textScale, List<DisplayFeature> features})>[
      (name: '320x568 at 1.5x text', size: TestWindows.smallPhone, textScale: 1.5, features: <DisplayFeature>[]),
      (name: 'tabletop', size: TestWindows.tabletop, textScale: 1, features: <DisplayFeature>[TestWindows.tabletopFold]),
      (name: 'book', size: TestWindows.book, textScale: 1, features: <DisplayFeature>[TestWindows.bookHinge]),
    ];
    for (final ({String name, Size size, double textScale, List<DisplayFeature> features}) window in windows) {
      testWidgets('every step fits ${window.name} and Start saving stays on screen', (WidgetTester tester) async {
        await open(tester, size: window.size, textScale: window.textScale, displayFeatures: window.features);
        expect(tester.takeException(), isNull);
        await item(tester);
        expect(tester.takeException(), isNull);
        await tapKey(tester, 'afford-yes');
        await keys(tester, '60000');
        expect(tester.takeException(), isNull);
        await tapKey(tester, 'afford-see-answer');
        expect(tester.takeException(), isNull);

        final Rect key = tester.getRect(find.byKey(const ValueKey<String>('afford-start-saving')));
        expect((Offset.zero & window.size).inflate(0.5).contains(key.bottomRight), isTrue, reason: '$key');
        expect((Offset.zero & window.size).inflate(0.5).contains(key.topLeft), isTrue, reason: '$key');
      });
    }
  });
}
