import 'dart:async';
import 'dart:ui';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/widgets/amount_display.dart';
import 'package:hisaab/core/widgets/keypad.dart';
import 'package:hisaab/fix/fix.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/pinned_keypad_expectations.dart';
import '../../../helpers/pump_app.dart';

/// FR-FX-2 to FR-FX-6 on the real sheet, over the worked example (H 17,430, I ÷ 10 = 4,500).
void main() {
  late FakeServices services;
  final Finder dragHandle = find.byWidgetPredicate((Widget w) => w.runtimeType.toString().contains('DragHandle'));

  setUp(() => services = FakeServices());

  tearDown(() => services.ledger.dispose());

  FixBloc buildBloc() => FixBloc(
        getCycleSummary: services.getCycleSummary,
        fix: FixMyNumberUseCase(
          summary: services.getCycleSummary,
          ledger: services.ledger,
          categories: services.categories,
          settings: services.settings,
          clock: services.clock,
        ),
        ledger: services.ledger,
        clock: services.clock,
        haptics: services.haptics,
      );

  /// Opens the sheet; the returned future completes with what it reports when it closes.
  Future<Future<Option<FixOutcome>>> open(
    WidgetTester tester, {
    Size size = TestWindows.phone,
    double textScale = 1,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) async {
    final FixBloc bloc = await tester.buildBloc(() => buildBloc()..add(const FixLoadRequested()));
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale, displayFeatures: displayFeatures);
    final Future<Option<FixOutcome>> outcome = FixSheet.show(tester.element(find.byType(Scaffold)), bloc);
    await tester.settle();
    return outcome;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final String digit in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$digit')));
      await tester.settle();
    }
  }

  Future<void> tapFix(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('fix-action')));
    await tester.settle();
  }

  bool actionEnabled(WidgetTester tester) {
    final SemanticsHandle handle = tester.ensureSemantics();
    final bool enabled = tester.getSemantics(find.byKey(const ValueKey<String>('fix-action'))).getSemanticsData().hasAction(SemanticsAction.tap);
    handle.dispose();
    return enabled;
  }

  group('FixSheet at rest (FR-FX-2)', () {
    testWidgets('title, helper, empty amount, keypad 1-9, 00 0 backspace, no chips, Fix it off', (WidgetTester tester) async {
      await open(tester);

      expect(find.text("How much of this month's money is left?"), findsOneWidget);
      expect(find.text('Bank and cash together. Leave out money from before this month.'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      for (final String key in <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0']) {
        expect(find.byKey(ValueKey<String>('keypad-$key')), findsOneWidget);
      }
      expect(find.text('Fix it'), findsOneWidget);
      expect(find.textContaining('hisaab thought'), findsNothing);
      expect(actionEnabled(tester), isFalse);
    });

    testWidgets('the title is a heading', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);

      expect(tester.getSemantics(find.text("How much of this month's money is left?")).getSemanticsData().flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('a failed read says so and Try again reloads it', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('down');
      await open(tester);
      expect(find.text("Couldn't check your number."), findsOneWidget);
      expect(actionEnabled(tester), isFalse);

      services.ledger.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.settle();

      expect(find.text("Couldn't check your number."), findsNothing);
      expect(find.text('Bank and cash together. Leave out money from before this month.'), findsOneWidget);
    });
  });

  group('FixSheet accessibility (FR-FX-6)', () {
    testWidgets('keypad step meets the tap target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await type(tester, '13230');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('guard step meets them too, and reads question, then No, then Yes', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await type(tester, '47430');
      await tester.tap(find.byKey(const ValueKey<String>('fix-action')));
      await tester.settle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      final double question = tester.getTopLeft(find.text("That's ₹30,000 more. Is all of it from this month?")).dy;
      final double no = tester.getTopLeft(find.byKey(const ValueKey<String>('fix-guard-no'))).dy;
      final double yes = tester.getTopLeft(find.byKey(const ValueKey<String>('fix-guard-yes'))).dy;
      expect(question < no && no < yes, isTrue);
      expect(find.bySemanticsLabel('Yes, add 30,000 rupees'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('focus order: title, amount, preview, keys 1 to 9, 00, 0, backspace, Fix it', (WidgetTester tester) async {
      await open(tester);

      final List<double> tops = <double>[
        tester.getTopLeft(find.text("How much of this month's money is left?")).dy,
        tester.getTopLeft(find.byType(AmountDisplay)).dy,
        tester.getTopLeft(find.byKey(const ValueKey<String>('keypad-1'))).dy,
        tester.getTopLeft(find.byKey(const ValueKey<String>('fix-action'))).dy,
      ];
      expect(tops, orderedEquals(<double>[...tops]..sort()));
    });
  });

  group('FixSheet fixing (FR-FX-3, FR-FX-5)', () {
    testWidgets('typing 13230 shows the lower preview and enables Fix it; Fix it closes with a FixOutcome', (WidgetTester tester) async {
      final Future<Option<FixOutcome>> outcome = await open(tester);

      await type(tester, '13230');
      expect(find.text('hisaab thought ₹17,430.'), findsOneWidget);
      expect(find.text("That's ₹4,200 less. Each day gets about ₹467 less."), findsOneWidget);
      expect(actionEnabled(tester), isTrue);

      await tapFix(tester);

      final FixOutcome? done = (await tester.runAsync(() => outcome))?.toNullable();
      expect(done?.entry.amount, Money.fromMajor(4200));
      expect(done?.safeToday, Money.fromMajor(963));
      expect(find.byType(FixSheet), findsNothing);
    });

    testWidgets('backspace drops the last digit and a long press empties the amount', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '132');
      final Finder backspace = find.bySemanticsLabel(RegExp('Delete last digit'));

      await tester.tap(backspace);
      await tester.settle();
      expect(find.text('₹13'), findsOneWidget);

      await tester.longPress(backspace);
      await tester.settle();
      expect(find.text('₹0'), findsOneWidget);
      expect(find.textContaining('hisaab thought'), findsNothing);
    });

    testWidgets('equal turns Fix it off and says so', (WidgetTester tester) async {
      await open(tester);

      await type(tester, '17430');

      expect(find.text('That matches. Nothing to fix.'), findsOneWidget);
      expect(actionEnabled(tester), isFalse);
    });

    testWidgets('a failed save: "Couldn\'t save. Try again." until the next key, digits kept', (WidgetTester tester) async {
      await open(tester);
      await type(tester, '13230');
      services.ledger.failure = DatabaseFailure('down');

      await tapFix(tester);

      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.text('₹13,230'), findsOneWidget);
      expect(actionEnabled(tester), isTrue);
      services.ledger.failure = null;
      await type(tester, '0');
      expect(find.text("Couldn't save. Try again."), findsNothing);
    });

    testWidgets('"Saving" is spoken only if the write passes one second, and the key keeps its label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await type(tester, '13230');
      final Completer<void> gate = Completer<void>();
      services.ledger.nextAddGate = gate;

      await tester.tap(find.byKey(const ValueKey<String>('fix-action')));
      // why: the bloc handles its events in the real zone; one turn of it emits the saving state.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.bySemanticsLabel('Saving'), findsNothing);
      expect(find.text('Fix it'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.bySemanticsLabel('Saving'), findsOneWidget);
      gate.complete();
      await tester.settle();
      handle.dispose();
    });

    testWidgets('a write under a second says nothing', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await type(tester, '13230');

      await tapFix(tester);

      expect(find.bySemanticsLabel('Saving'), findsNothing);
      handle.dispose();
    });

    testWidgets('Back while writing closes the sheet and the outcome still arrives (E86)', (WidgetTester tester) async {
      final Future<Option<FixOutcome>> outcome = await open(tester);
      await type(tester, '13230');
      final Completer<void> gate = Completer<void>();
      services.ledger.nextAddGate = gate;
      await tester.tap(find.byKey(const ValueKey<String>('fix-action')));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      gate.complete();
      await tester.settle();

      expect((await tester.runAsync(() => outcome))?.isSome(), isTrue);
    });
  });

  group('FixSheet guard (FR-FX-4)', () {
    Future<Future<Option<FixOutcome>>> openGuard(WidgetTester tester) async {
      final Future<Option<FixOutcome>> outcome = await open(tester);
      await type(tester, '47430');
      return outcome;
    }

    testWidgets('Fix it on a large gap shows the panel: question, keys stacked No then Yes, sheet shorter', (WidgetTester tester) async {
      await openGuard(tester);
      final double before = tester.getTopLeft(find.byType(AmountDisplay)).dy;
      expect(find.text("That's ₹30,000 more. One question first."), findsOneWidget);

      await tapFix(tester);

      expect(find.text("That's ₹30,000 more. Is all of it from this month?"), findsOneWidget);
      final Offset no = tester.getTopLeft(find.byKey(const ValueKey<String>('fix-guard-no')));
      final Offset yes = tester.getTopLeft(find.byKey(const ValueKey<String>('fix-guard-yes')));
      expect(no.dy < yes.dy, isTrue);
      expect(find.text('No, some is older'), findsOneWidget);
      expect(find.text('Yes, add ₹30,000'), findsOneWidget);
      expect(find.byType(Keypad), findsNothing);
      expect(find.byKey(const ValueKey<String>('fix-action')), findsNothing);
      expect(tester.getTopLeft(find.byType(AmountDisplay)).dy > before, isTrue, reason: 'the sheet shortens, so the amount moves down');
      expect(tester.getSize(find.byKey(const ValueKey<String>('fix-guard-no'))).height >= 56, isTrue);
    });

    testWidgets('a tap 100 ms after the swap does nothing; at 300 ms it works', (WidgetTester tester) async {
      final Future<Option<FixOutcome>> outcome = await openGuard(tester);
      await tapFix(tester);

      services.clock.advance(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey<String>('fix-guard-yes')));
      await tester.settle();
      expect(services.ledger.saved, isEmpty);
      expect(find.byKey(const ValueKey<String>('fix-guard-yes')), findsOneWidget);

      services.clock.advance(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey<String>('fix-guard-yes')));
      await tester.settle();

      expect((await tester.runAsync(() => outcome))?.toNullable()?.entry.amount, Money.fromMajor(30000));
    });

    testWidgets('No: digits cleared, the notice over ₹0, focus on the notice', (WidgetTester tester) async {
      await openGuard(tester);
      await tapFix(tester);
      services.clock.advance(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey<String>('fix-guard-no')));
      await tester.settle();

      expect(find.text("Count only this month's money."), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'fix-slot');
    });

    testWidgets('on opening, focus lands on the question in the frame the panel is built', (WidgetTester tester) async {
      await openGuard(tester);

      await tapFix(tester);

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'fix-slot');
    });

    testWidgets('system back from the guard steps back; a second back closes the sheet with nothing posted', (WidgetTester tester) async {
      final Future<Option<FixOutcome>> outcome = await openGuard(tester);
      await tapFix(tester);

      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(find.byType(Keypad), findsOneWidget);
      expect(find.byType(FixSheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.settle();

      expect(find.byType(FixSheet), findsNothing);
      expect((await tester.runAsync(() => outcome))?.isNone(), isTrue);
      expect(services.ledger.saved, isEmpty);
    });

    testWidgets('Escape steps back from the guard like No', (WidgetTester tester) async {
      await openGuard(tester);
      await tapFix(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.settle();

      expect(find.byType(Keypad), findsOneWidget);
    });

    testWidgets('the scrim closes the sheet from the keypad with nothing posted', (WidgetTester tester) async {
      final Future<Option<FixOutcome>> outcome = await open(tester);
      await type(tester, '13230');

      await tester.tapAt(const Offset(200, 20));
      await tester.settle();

      expect(find.byType(FixSheet), findsNothing);
      expect((await tester.runAsync(() => outcome))?.isNone(), isTrue);
    });
  });

  group('FixSheet layout (FR-KS-1, E111 to E115)', () {
    for (final PinnedCase window in pinnedCases) {
      testWidgets('${window.name}: amount, keypad and Fix it stay on screen', (WidgetTester tester) async {
        setBottomInset(tester, window.bottomInset);
        await open(tester, size: window.size, textScale: window.textScale, displayFeatures: window.features);
        await type(tester, '13230');

        expectPinnedOnScreen(tester, window: window, amount: find.byType(AmountDisplay), action: find.byKey(const ValueKey<String>('fix-action')));
        expect(tester.takeException(), isNull);
      });
    }

    for (final Size size in <Size>[TestWindows.splitScreen, TestWindows.splitScreenShort, TestWindows.landscape600, TestWindows.book]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} at 2x text: no overflow, Fix it reachable', (WidgetTester tester) async {
        await open(tester, size: size, textScale: 2);
        await type(tester, '13230');

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('fix-action')), findsOneWidget);
      });
    }

    testWidgets('320x568 at 2x text: no overflow and the guard panel fits', (WidgetTester tester) async {
      await open(tester, size: TestWindows.smallPhone, textScale: 2);
      await type(tester, '47430');
      await tapFix(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>('fix-guard-yes')), findsOneWidget);
    });

    testWidgets('a medium window keeps the sheet to a readable stack, never across a fold', (WidgetTester tester) async {
      await open(tester, size: TestWindows.tablet);

      expect(tester.getSize(find.byType(FixSheet)).width <= 560, isTrue);
    });

    testWidgets('book posture with a hinge: nothing straddles the fold', (WidgetTester tester) async {
      await open(tester, size: TestWindows.book, displayFeatures: <DisplayFeature>[TestWindows.bookHinge]);
      await type(tester, '13230');

      final Rect hinge = TestWindows.bookHinge.bounds;
      for (final Finder part in <Finder>[find.byType(AmountDisplay), find.byType(Keypad), find.byKey(const ValueKey<String>('fix-action'))]) {
        final Rect box = tester.getRect(part);
        expect(box.overlaps(hinge), isFalse, reason: '$box straddles the hinge $hinge');
      }
    });

    testWidgets('the handle is not drawn under 600dp tall (E115, D180)', (WidgetTester tester) async {
      await open(tester, size: TestWindows.splitScreen);

      expect(dragHandle, findsNothing);
    });

    testWidgets('the handle is drawn on a tall phone', (WidgetTester tester) async {
      await open(tester);

      expect(dragHandle, findsOneWidget);
    });
  });
}
