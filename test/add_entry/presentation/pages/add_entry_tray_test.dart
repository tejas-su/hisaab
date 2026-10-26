import 'dart:ui';

import 'package:expense_tracker/add_entry/add_entry.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fake_services.dart';
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
        saveEntry: SaveEntry(ledger: services.ledger, clock: services.clock),
        deleteEntry: DeleteEntry(ledger: services.ledger),
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
      await tester.tap(find.bySemanticsLabel('Delete last digit. Long-press to clear'));
      await tester.pump();
      expect(find.text('₹24'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Long-press to clear'));
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

    testWidgets('shows the overspend preview from the mockup (FR-AD-3)', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '2450');
      expect(find.text("₹1,020 over today's share · tomorrow ₹1,722"), findsOneWidget);
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
  });

}
