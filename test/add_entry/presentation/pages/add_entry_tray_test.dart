import 'dart:async';
import 'dart:ui';

import 'package:flutter/semantics.dart';

import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/add_entry/presentation/widgets/kind_switch.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/core/widgets/amount_text.dart';
import 'package:hisaab/core/widgets/hisaab_chip.dart';
import 'package:hisaab/core/widgets/keypad.dart';
import 'package:hisaab/core/widgets/shake.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart' as habit;
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const DisplayFeature _tabletopFold = DisplayFeature(
  bounds: Rect.fromLTRB(0, 420, 701, 420),
  type: DisplayFeatureType.fold,
  state: DisplayFeatureState.postureHalfOpened,
);

void main() {
  late FakeServices services;
  late CycleSummary summary;

  setUp(() async {
    services = FakeServices();
    summary = (await services.getCycleSummary(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));
  });

  tearDown(() => services.dispose());

  AddEntryBloc bloc({Option<Entry> editing = const Option<Entry>.none()}) => AddEntryBloc(
        saveEntry: SaveEntry(ledger: services.ledger, recurring: services.recurring, clock: services.clock),
        deleteEntry: DeleteEntry(ledger: services.ledger),
        addOwnCategory: AddOwnCategory(categories: services.categories),
        haptics: services.haptics,
        clock: services.clock,
        categories: seedCategories,
        summary: Option<CycleSummary>.of(summary),
        editing: editing,
      );

  Future<void> open(
    WidgetTester tester, {
    Option<Entry> editing = const Option<Entry>.none(),
    Size size = TestWindows.phone,
    double textScale = 1,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(onPressed: () => AddEntryTray.show(context, bloc(editing: editing)), child: const Text('open')),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      displayFeatures: displayFeatures,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final String key in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
    }
    await tester.pump();
  }

  group('AddEntryTray (FR-AD)', () {
    testWidgets('⌫ drops the last digit and a long-press clears the amount (FR-AD-2)', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '245');
      await tester.tap(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await tester.pump();
      expect(find.text('₹24'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'));
      await tester.pump();
      expect(find.text('₹24'), findsNothing);
    });

    testWidgets('Add → digits → Next → tile saves and closes (the 4-tap path)', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '60');
      expect(find.text('₹60'), findsOneWidget);
      expect(find.text('Leaves ₹1,370 for today'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      expect(find.text('What was it for?'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Food. Save'));
      await settle(tester);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(services.ledger.saved.single.amount, Money.fromMajor(60));
      expect(services.haptics.events.last, 'success');
    });

    testWidgets('show completes only once the tray has fully closed (FR-AD-5, D91)', (WidgetTester tester) async {
      bool closed = false;
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () => AddEntryTray.show(context, bloc()).then((void _) => closed = true),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect((find.byType(AddEntryTray).evaluate().isNotEmpty, closed), (true, false));
      await tester.pumpAndSettle();
      expect((find.byType(AddEntryTray).evaluate().isEmpty, closed), (true, true));
    });

    testWidgets('shows the overspend preview from the mockup (FR-AD-3)', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '2450');
      expect(find.text("₹1,020 over today's share · tomorrow's share ₹1,722"), findsOneWidget);
    });

    testWidgets('quick chips add, Got switches tiles, back keeps the amount', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('quick-100')));
      await tester.tap(find.byKey(const ValueKey<String>('quick-50')));
      await tester.pump();
      expect(find.text('₹150'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('kind-got')));
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      expect(find.text('Where did it come from?'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tile-salary')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('back-to-amount')));
      await tester.pumpAndSettle();
      expect(find.text('₹150'), findsOneWidget);
    });

    testWidgets('system back: step 2 → step 1 → closed without saving (FR-AD-7)', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '5');
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('add-next')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AddEntryTray), findsNothing);
      expect(services.ledger.saved, isEmpty);
    });

    testWidgets('a 10th digit shakes and is refused', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '9999999999');
      expect(find.text('₹99,99,99,999'), findsOneWidget);
      expect(services.haptics.events.last, 'reject');
    });

    testWidgets('date chip: Yesterday, and a note is saved with the entry', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '120');
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('date-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('date-yesterday')));
      await tester.pumpAndSettle();
      expect(find.text('Yesterday'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('note-chip')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey<String>('note-field')), 'Auto to office');
      await tester.tap(find.bySemanticsLabel('Travel. Save'));
      await settle(tester);
      expect(services.ledger.saved.single.date, WorkedExample.today.addDays(-1));
      expect(services.ledger.saved.single.note, 'Auto to office');
    });

    testWidgets('date chip: Pick a date uses the calendar', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '120');
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('date-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('date-pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('20 Oct'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('date-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('date-today')));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('a failed save keeps the tray open with the message (FR-AD-6)', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('disk full');
      await open(tester);
      await type(tester, '60');
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Food. Save'));
      await settle(tester);
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.byType(AddEntryTray), findsOneWidget);
    });

    testWidgets('edit mode is prefilled and can delete (FR-AD-8)', (WidgetTester tester) async {
      await open(tester, editing: Option<Entry>.of(WorkedExample.entries[3]));
      expect(find.text('₹60'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('delete-entry')));
      await settle(tester);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(services.ledger.entries.map((Entry e) => e.id), isNot(contains(4)));
    });

    final List<(String, Size, double, List<DisplayFeature>)> windows = <(String, Size, double, List<DisplayFeature>)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2, const <DisplayFeature>[]),
      ('a phone in landscape', TestWindows.phoneLandscape, 1, const <DisplayFeature>[]),
      ('a tablet', TestWindows.tablet, 1, const <DisplayFeature>[]),
      ('tabletop posture', const Size(701, 841), 1, const <DisplayFeature>[_tabletopFold]),
    ];
    for (final (String name, Size size, double scale, List<DisplayFeature> features) in windows) {
      testWidgets('both steps lay out without overflow on $name', (WidgetTester tester) async {
        await open(tester, size: size, textScale: scale, displayFeatures: features);
        await type(tester, '2450');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey<String>('add-next')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tabletop: the whole tray sits below the fold and takes taps', (WidgetTester tester) async {
      await open(tester, size: const Size(701, 841), displayFeatures: const <DisplayFeature>[_tabletopFold]);
      expect(tester.getRect(find.byType(AddEntryTray)).top, greaterThanOrEqualTo(420));
      await tester.tap(find.byKey(const ValueKey<String>('keypad-7')));
      await tester.pump();
      expect(find.text('₹7'), findsOneWidget);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await type(tester, '60');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    for (final (ThemeMode mode, HisaabColors colors) in <(ThemeMode, HisaabColors)>[
      (ThemeMode.light, HisaabColors.light),
      (ThemeMode.dark, HisaabColors.dark),
    ]) {
      testWidgets('dims the page with the ${mode.name} scrim token (UI_DESIGN §3.5)', (WidgetTester tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: TextButton(onPressed: () => AddEntryTray.show(context, bloc()), child: const Text('open')),
              ),
            ),
          ),
          themeMode: mode,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color, colors.scrim);
      });
    }
  });

  group('controls on the tray keep the hairline step, since a control fill is the tray in light (D100)', () {
    Color? chipFill(WidgetTester tester, Finder chip) =>
        (tester.widget<Container>(find.descendant(of: chip, matching: find.byType(Container)).first).decoration! as ShapeDecoration).color;

    Color? fieldFill(WidgetTester tester, Finder field) =>
        tester.widget<InputDecorator>(find.descendant(of: field, matching: find.byType(InputDecorator))).decoration.fillColor;

    Iterable<Color?> everyChipFill(WidgetTester tester) =>
        find.byType(HisaabChip).evaluate().map((Element chip) => chipFill(tester, find.byWidget(chip.widget)));

    testWidgets('the quick-add chips', (WidgetTester tester) async {
      await open(tester);
      expect(everyChipFill(tester), isNotEmpty);
      expect(everyChipFill(tester), everyElement(HisaabColors.light.hairline));
    });

    testWidgets('the delete chip and an entry’s open note field', (WidgetTester tester) async {
      await open(tester, editing: Option<Entry>.of(WorkedExample.entries[3]));
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      expect(chipFill(tester, find.byKey(const ValueKey<String>('delete-entry'))), HisaabColors.light.hairline);
      expect(fieldFill(tester, find.byKey(const ValueKey<String>('note-field'))), HisaabColors.light.hairline);
    });

    testWidgets('the date and note chips, the date sheet’s chips and the calendar’s typed-date field', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '120');
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await tester.pumpAndSettle();
      for (final String key in <String>['date-chip', 'note-chip']) {
        expect(chipFill(tester, find.byKey(ValueKey<String>(key))), HisaabColors.light.hairline, reason: key);
      }
      await tester.tap(find.byKey(const ValueKey<String>('date-chip')));
      await tester.pumpAndSettle();
      for (final String key in <String>['date-today', 'date-yesterday', 'date-pick']) {
        expect(chipFill(tester, find.byKey(ValueKey<String>(key))), HisaabColors.light.hairline, reason: key);
      }
      await tester.tap(find.byKey(const ValueKey<String>('date-pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      expect(fieldFill(tester, find.byType(InputDatePickerFormField)), HisaabColors.light.hairline);
    });
  });

  group('AddEntryTray your usual (FR-AD-10)', () {
    const ValueKey<String> pillKey = ValueKey<String>('usual-pill');
    final Finder pill = find.byKey(pillKey);
    final Finder slot = find.byKey(const ValueKey<String>('usual-slot'));
    final Finder chips = find.byKey(const ValueKey<String>('quick-10'));
    final Finder amount = find.byType(Shake);
    final List<Category> withChai = <Category>[...seedCategories, habit.chai];
    final Option<UsualSpend> chaiTwenty = Option<UsualSpend>.of(UsualSpend(category: habit.chai, amount: Money.fromMajor(20)));

    AddEntryBloc usualBloc({
      Option<UsualSpend>? usual,
      Option<Entry> editing = const Option<Entry>.none(),
      EntryKind kind = EntryKind.spent,
    }) =>
        AddEntryBloc(
          saveEntry: SaveEntry(ledger: services.ledger, recurring: services.recurring, clock: services.clock),
          deleteEntry: DeleteEntry(ledger: services.ledger),
          addOwnCategory: AddOwnCategory(categories: services.categories),
          haptics: services.haptics,
          clock: services.clock,
          categories: withChai,
          summary: Option<CycleSummary>.of(summary),
          editing: editing,
          kind: kind,
          usual: usual ?? chaiTwenty,
        );

    Future<void> pumpOpener(
      WidgetTester tester, {
      Option<UsualSpend>? usual,
      Option<Entry> editing = const Option<Entry>.none(),
      EntryKind kind = EntryKind.spent,
      Size size = TestWindows.phone,
      double textScale = 1,
      List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
      ThemeMode themeMode = ThemeMode.light,
      bool reduceMotion = false,
    }) =>
        pumpApp(
          tester,
          Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: TextButton(
                  onPressed: () => AddEntryTray.show(context, usualBloc(usual: usual, editing: editing, kind: kind)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          size: size,
          textScale: textScale,
          displayFeatures: displayFeatures,
          themeMode: themeMode,
          reduceMotion: reduceMotion,
        );

    Future<void> openUsual(
      WidgetTester tester, {
      Option<UsualSpend>? usual,
      Option<Entry> editing = const Option<Entry>.none(),
      EntryKind kind = EntryKind.spent,
      Size size = TestWindows.phone,
      double textScale = 1,
      List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
      ThemeMode themeMode = ThemeMode.light,
      bool reduceMotion = false,
    }) async {
      await pumpOpener(
        tester,
        usual: usual,
        editing: editing,
        kind: kind,
        size: size,
        textScale: textScale,
        displayFeatures: displayFeatures,
        themeMode: themeMode,
        reduceMotion: reduceMotion,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    ScrollPosition headerScroll(WidgetTester tester) => tester
        .state<ScrollableState>(find.ancestor(of: find.byType(KindSwitch), matching: find.byType(Scrollable)).first)
        .position;

    Color? pillFill(WidgetTester tester) => (tester
            .widget<AnimatedContainer>(find.descendant(of: pill, matching: find.byType(AnimatedContainer)))
            .decoration! as ShapeDecoration)
        .color;

    testWidgets('the header fits without scrolling on a 412×915 phone (layout guard)', (WidgetTester tester) async {
      await openUsual(tester, usual: const Option<UsualSpend>.none());
      expect(headerScroll(tester).maxScrollExtent, 0);
      expect(tester.getRect(chips).bottom, lessThanOrEqualTo(tester.getRect(find.byType(Keypad)).top));
    });

    testWidgets('the pill is there after one pump (AC-1, NFR-1)', (WidgetTester tester) async {
      await pumpOpener(tester);
      await tester.tap(find.text('open'));
      await tester.pump();
      expect(pill, findsOneWidget);
      expect(find.descendant(of: pill, matching: find.text('Chai ₹20 · your usual', findRichText: true)), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('no usual: the slot is empty and nothing else moved (FR-AD-1, D153)', (WidgetTester tester) async {
      Option<UsualSpend> usual = chaiTwenty;
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(onPressed: () => AddEntryTray.show(context, usualBloc(usual: usual)), child: const Text('open')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(pill, findsOneWidget);
      final Rect chipsWithPill = tester.getRect(chips);
      final Rect amountWithPill = tester.getRect(amount);
      final Rect keypadWithPill = tester.getRect(find.byType(Keypad));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      usual = const Option<UsualSpend>.none();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(pill, findsNothing);
      expect(tester.getSize(slot).height, 48);
      expect(tester.getRect(chips), chipsWithPill);
      expect(tester.getRect(amount), amountWithPill);
      expect(tester.getRect(find.byType(Keypad)), keypadWithPill);
    });

    testWidgets('layout B: 20dp switch to amount, 4dp to the slot, 8dp to the chips (UI_DESIGN §5.3)', (WidgetTester tester) async {
      await openUsual(tester);
      expect(tester.getRect(amount).top - tester.getRect(find.byType(KindSwitch)).bottom, 20);
      expect(tester.getRect(slot).top - tester.getRect(amount).bottom, 4);
      expect(tester.getSize(slot).height, 48);
      expect(tester.getRect(chips).top - tester.getRect(slot).bottom, 8);
      expect(tester.getRect(pill).center.dx, moreOrLessEquals(tester.getRect(slot).center.dx, epsilon: 0.5));
      expect(tester.getRect(find.byType(AmountText)).center.dx, moreOrLessEquals(tester.getRect(slot).center.dx, epsilon: 0.5));
    });

    testWidgets('the short tray keeps 12dp above the amount (UI_DESIGN §5.3)', (WidgetTester tester) async {
      await openUsual(tester, size: TestWindows.phoneLandscape);
      expect(tester.getRect(amount).top - tester.getRect(find.byType(KindSwitch)).bottom, 12);
      expect(tester.getRect(slot).top - tester.getRect(amount).bottom, 4);
      expect(tester.getRect(chips).top - tester.getRect(slot).bottom, 8);
    });

    testWidgets('the first key crossfades the pill to the preview in 150ms and the chips do not move (AC-3)', (WidgetTester tester) async {
      await openUsual(tester);
      final Rect before = tester.getRect(chips);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-5')));
      await tester.pump();
      await tester.pump();
      expect(pill, findsOneWidget);
      expect(find.text('Leaves ₹1,425 for today'), findsOneWidget);
      expect(tester.getRect(chips), before);
      await tester.pump(const Duration(milliseconds: 75));
      expect(pill, findsOneWidget);
      expect(tester.getRect(chips), before);
      await tester.pump(const Duration(milliseconds: 75));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(pill, findsNothing);
      expect(find.text('Leaves ₹1,425 for today'), findsOneWidget);
      expect(tester.getRect(chips), before);
    });

    final List<(String, Future<void> Function(WidgetTester))> inputs = <(String, Future<void> Function(WidgetTester))>[
      ('a chip', (WidgetTester tester) => tester.tap(find.byKey(const ValueKey<String>('quick-20')))),
      ('⌫', (WidgetTester tester) => tester.tap(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'))),
      ('long-press ⌫', (WidgetTester tester) => tester.longPress(find.bySemanticsLabel('Delete last digit. Touch and hold to clear all'))),
      ('Got', (WidgetTester tester) => tester.tap(find.byKey(const ValueKey<String>('kind-got')))),
    ];
    for (final (String name, Future<void> Function(WidgetTester) act) in inputs) {
      testWidgets('$name hides it (AC-3)', (WidgetTester tester) async {
        await openUsual(tester);
        final Rect before = tester.getRect(chips);
        await act(tester);
        await tester.pumpAndSettle();
        expect(pill, findsNothing);
        expect(tester.getRect(chips), before);
      });
    }

    testWidgets('Spent again does not bring it back (AC-3)', (WidgetTester tester) async {
      await openUsual(tester);
      await tester.tap(find.byKey(const ValueKey<String>('kind-got')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('kind-spent')));
      await tester.pumpAndSettle();
      expect(pill, findsNothing);
    });

    testWidgets('reopening the tray shows it again (AC-3)', (WidgetTester tester) async {
      await openUsual(tester);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-5')));
      await tester.pumpAndSettle();
      expect(pill, findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(AddEntryTray), findsNothing);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(pill, findsOneWidget);
    });

    testWidgets('a tap saves ₹20 in Chai and closes the tray (AC-4)', (WidgetTester tester) async {
      await openUsual(tester);
      await tester.tap(pill);
      await settle(tester);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(
        services.ledger.saved.single,
        EntryDraft(amount: Money.fromMajor(20), kind: EntryKind.spent, categoryId: habit.chai.id, date: WorkedExample.today),
      );
      expect(services.haptics.events, <String>['success']);
    });

    testWidgets('the pill is ink while it saves, step 1 stays, and a second tap writes nothing more (AC-4)', (WidgetTester tester) async {
      final Completer<void> slowSave = Completer<void>();
      services.ledger.nextAddGate = slowSave;
      await openUsual(tester);
      expect(pillFill(tester), HisaabColors.light.surface);
      await tester.tap(pill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(pillFill(tester), HisaabColors.light.ink);
      expect(find.byKey(const ValueKey<String>('add-next')), findsOneWidget);
      expect(find.text('What was it for?'), findsNothing);
      await tester.tap(pill);
      await tester.pump();
      slowSave.complete();
      await settle(tester);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(services.ledger.saved, hasLength(1));
    });

    testWidgets("a failed save keeps the tray open with Couldn't save. Try again. on the pill; a tap tries again (AC-4)", (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('disk full');
      await openUsual(tester);
      final Rect before = tester.getRect(chips);
      await tester.tap(pill);
      await settle(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.descendant(of: pill, matching: find.text("Couldn't save. Try again.", findRichText: true)), findsOneWidget);
      expect(pillFill(tester), HisaabColors.light.surface);
      expect(tester.getRect(chips), before);
      expect(services.haptics.events.last, 'reject');
      services.ledger.failure = null;
      await tester.tap(pill);
      await settle(tester);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(services.ledger.saved.single.categoryId, habit.chai.id);
    });

    testWidgets('edit mode shows no pill (AC-1)', (WidgetTester tester) async {
      await openUsual(tester, editing: Option<Entry>.of(WorkedExample.entries[3]));
      expect(pill, findsNothing);
    });

    testWidgets('a tray opened on Got shows no pill (AC-1)', (WidgetTester tester) async {
      await openUsual(tester, kind: EntryKind.got);
      expect(pill, findsNothing);
    });

    final List<(String, Size, double, List<DisplayFeature>)> windows = <(String, Size, double, List<DisplayFeature>)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2, const <DisplayFeature>[]),
      ('a 320dp phone at 1.5× text', TestWindows.smallPhone, 1.5, const <DisplayFeature>[]),
      ('a phone in landscape', TestWindows.phoneLandscape, 1, const <DisplayFeature>[]),
      ('a tablet', TestWindows.tablet, 1, const <DisplayFeature>[]),
      ('an unfolded foldable', TestWindows.foldableUnfolded, 1, const <DisplayFeature>[]),
      ('a foldable in landscape', TestWindows.foldableLandscape, 1, const <DisplayFeature>[]),
      ('tabletop posture', const Size(701, 841), 1, const <DisplayFeature>[_tabletopFold]),
    ];
    for (final (String name, Size size, double scale, List<DisplayFeature> features) in windows) {
      testWidgets('both steps lay out without overflow with a usual on $name (NFR-8)', (WidgetTester tester) async {
        await openUsual(tester, size: size, textScale: scale, displayFeatures: features);
        expect(tester.takeException(), isNull);
        await type(tester, '2450');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey<String>('add-next')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final Size size in <Size>[const Size(360, 640), TestWindows.smallPhone]) {
      testWidgets('on ${size.width.round()}×${size.height.round()} the pill can be scrolled into view and nothing overflows (OQ-8)',
          (WidgetTester tester) async {
        await openUsual(tester, size: size);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(pill);
        await tester.pumpAndSettle();
        final Rect viewport = tester.getRect(find.ancestor(of: find.byType(KindSwitch), matching: find.byType(Scrollable)).first);
        expect(tester.getRect(pill).top, greaterThanOrEqualTo(viewport.top));
        expect(tester.getRect(pill).bottom, lessThanOrEqualTo(viewport.bottom));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tabletop: the pill sits beside the keypad, below the fold (UI_DESIGN §13)', (WidgetTester tester) async {
      await openUsual(tester, size: const Size(701, 841), displayFeatures: const <DisplayFeature>[_tabletopFold]);
      expect(tester.getRect(pill).top, greaterThanOrEqualTo(420));
      expect(tester.getRect(pill).right, lessThanOrEqualTo(tester.getRect(find.byType(Keypad)).left));
      expect(tester.getRect(amount).top - tester.getRect(find.byType(KindSwitch)).bottom, 12);
    });

    testWidgets('TalkBack order: Spent/Got, amount, the pill, the chips (AC-5)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openUsual(tester);
      final List<String> labels = tester.semantics
          .simulatedAccessibilityTraversal(startNode: find.semantics.byLabel('Spent'), endNode: find.semantics.byLabel('Add 10 rupees'))
          .map((SemanticsNode node) => node.label)
          .toList();
      expect(labels, <String>['Spent', 'Got', '0 rupees', 'Add Chai, 20 rupees, your usual', 'Add 10 rupees']);
      handle.dispose();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('with a usual, step 1 meets tap-target, label and contrast guidelines in ${mode.name} (NFR-4)', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await openUsual(tester, themeMode: mode);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
