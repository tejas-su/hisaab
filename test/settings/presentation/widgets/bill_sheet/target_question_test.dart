import 'dart:ui';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/widgets/amount_display.dart';
import 'package:hisaab/core/widgets/keypad_key.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/bloc_dispatch.dart';
import '../../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../../helpers/pinned_keypad_expectations.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/saving_sheet.dart';

/// *Saving up to* on a saving's sheet: the row, the question, the slot and *Clear* (SPEC BR-23,
/// FR-SE-1 AC-T1 to AC-T4, AC-T6, AC-T7, AC-T12).
void main() {
  late SavingSheet sheet;

  setUp(() => sheet = SavingSheet());
  tearDown(() => sheet.dispose());

  final Finder row = find.byKey(const ValueKey<String>('bill-row-target'));
  final Finder save = find.byKey(const ValueKey<String>('target-save'));
  final Finder clear = find.byKey(const ValueKey<String>('target-clear'));
  final Finder slot = find.byKey(const ValueKey<String>('target-slot'));
  final Finder setAside = find.byKey(const ValueKey<String>('bill-set-aside'));

  String lineOne(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey<String>('target-slot-line-1'))).data!;
  bool saveEnabled(WidgetTester tester) => tester.widget<SignalKey>(save).onPressed != null;

  group('the row (AC-T1, AC-T7)', () {
    testWidgets('a saving with no target reads "Not set" and is spoken as one sentence', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await sheet.open(tester, SavingSheet.insurance());

      expect(find.descendant(of: row, matching: find.text('Saving up to')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('Not set')), findsOneWidget);
      expect(tester.getSemantics(row).label, 'Set saving up to. Not set yet.');
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets('a saving with a target reads the amount', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));

      expect(find.descendant(of: row, matching: find.text('₹50,000')), findsOneWidget);
      expect(tester.getSemantics(row).label, 'Change saving up to, 50,000 rupees');
      handle.dispose();
    });

    testWidgets('it is the last row, after Name', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());

      expect(tester.getTopLeft(row).dy, greaterThan(tester.getTopLeft(find.byKey(const ValueKey<String>('bill-row-name'))).dy));
    });

    testWidgets('a bill never shows it', (WidgetTester tester) async {
      await sheet.open(tester, WorkedExample.electricity);

      expect(row, findsNothing);
    });
  });

  group('the slip line (AC-T6, B4)', () {
    testWidgets('with a target it reads as the Savings row, and is spoken without the dot or the no-break space', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));

      expect(tester.widget<Text>(setAside).data, '₹12,000 set aside · done by Dec 2029');
      final String spoken = tester.getSemantics(find.text('Insurance').first).label;
      expect(spoken, contains('12,000 rupees set aside, done by December 2029'));
      expect(spoken, isNot(contains('·')));
      expect(spoken, isNot(contains(' ')));
      handle.dispose();
    });

    testWidgets('with a target and nothing set aside it names the target', (WidgetTester tester) async {
      sheet.ledger.entries.removeWhere((Entry e) => e.recurringId == 5);
      await sheet.open(tester, SavingSheet.insurance(rupees: 3000));

      expect(tester.widget<Text>(setAside).data, 'Up to ₹3,000 · done by Jan 2027');
    });

    testWidgets('a target over 10 years away says so', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 200000));

      expect(tester.widget<Text>(setAside).data, '₹12,000 set aside · over 10 years to go');
    });

    testWidgets('without a target the line is unchanged', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());

      expect(tester.widget<Text>(setAside).data, '₹12,000 set aside');
    });
  });

  group('the question (AC-T2 to AC-T4)', () {
    testWidgets('with no target: title, empty amount, the blank line, Save off and no Clear', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());

      await sheet.openTarget(tester);

      expect(find.text('How much are you saving up to?'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(lineOne(tester), 'Type the amount you want to reach.');
      expect(find.text("Your daily number doesn't change."), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      expect(clear, findsNothing);
    });

    testWidgets('the line follows the digits: estimate, this year, reached and far', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());
      await sheet.openTarget(tester);

      await sheet.type(tester, '50000');
      expect(lineOne(tester), 'At ₹1,000 a month, done by Dec 2029.');
      expect(saveEnabled(tester), isTrue);

      await tester.tap(find.byType(KeypadKey).last);
      await tester.settle();
      expect(find.text('₹5,000'), findsOneWidget);

      await tester.longPress(find.byType(KeypadKey).last);
      await tester.settle();
      await sheet.type(tester, '13000');
      expect(lineOne(tester), 'At ₹1,000 a month, done by Nov.');

      await tester.longPress(find.byType(KeypadKey).last);
      await tester.settle();
      await sheet.type(tester, '12000');
      expect(lineOne(tester), "You've already set aside that much.");

      await sheet.type(tester, '00');
      expect(lineOne(tester), 'At ₹1,000 a month, that is over 10 years to go.');
    });

    testWidgets('a set target is prefilled with its own line, and Clear shows', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));

      await sheet.openTarget(tester);

      expect(find.text('₹50,000'), findsOneWidget);
      expect(lineOne(tester), 'At ₹1,000 a month, done by Dec 2029.');
      expect(clear, findsOneWidget);
    });

    testWidgets('Save writes, returns to the sheet, and the row reads the new amount with "Changed."', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());
      await sheet.openTarget(tester);
      await sheet.type(tester, '50000');

      await tester.tap(save);
      await tester.settle();

      expect(find.descendant(of: row, matching: find.text('₹50,000')), findsOneWidget);
      expect(find.text('Changed.'), findsOneWidget);
      expect(sheet.recurring.updates.single.target, Option<Money>.of(Money.fromMajor(50000)));
    });

    testWidgets('a failed save keeps the question with "Couldn\'t save. Try again."', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());
      await sheet.openTarget(tester);
      await sheet.type(tester, '50000');
      sheet.recurring.failure = DatabaseFailure('recurring');

      await tester.tap(save);
      await tester.settle();

      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.text('₹50,000'), findsOneWidget);
    });

    testWidgets('Clear removes the target at once: back on the sheet, the row reads "Not set" and "Changed."', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await sheet.open(tester, SavingSheet.insurance(rupees: 50000));
      await sheet.openTarget(tester);

      await tester.tap(clear);
      await tester.settle();

      expect(find.descendant(of: row, matching: find.text('Not set')), findsOneWidget);
      expect(find.text('Changed.'), findsOneWidget);
      expect(sheet.recurring.updates.single.target, const Option<Money>.none());
      expect(sheet.haptics.events.last, 'tick');
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(await tester.runAsync(() => outcome), isA<BillSheetChanged>());
    });

    testWidgets('Back drops the draft and writes nothing', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());
      await sheet.openTarget(tester);
      await sheet.type(tester, '500');

      await tester.binding.handlePopRoute();
      await tester.settle();

      expect(row, findsOneWidget);
      expect(sheet.recurring.updates, isEmpty);
    });
  });

  group('TalkBack (AC-T12, B3)', () {
    testWidgets('the blank line is not a live region; a line with figures is, read as its spoken twin', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await sheet.open(tester, SavingSheet.insurance());
      await sheet.openTarget(tester);

      expect(tester.getSemantics(find.byKey(const ValueKey<String>('target-slot-line-1'))).flagsCollection.isLiveRegion, isFalse);
      expect(tester.getSemantics(save).hint, 'Type an amount first.');

      await sheet.type(tester, '50000');
      final SemanticsNode live = tester.getSemantics(slot);
      expect(live.flagsCollection.isLiveRegion, isTrue);
      expect(live.label, "At 1,000 rupees a month, done by December 2029., Your daily number doesn't change.");
      handle.dispose();
    });

    testWidgets('the far line is spoken with rupees', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await sheet.open(tester, SavingSheet.insurance());
      await sheet.openTarget(tester);

      await sheet.type(tester, '200000');

      expect(
        tester.getSemantics(find.byKey(const ValueKey<String>('target-slot-line-1'))).label,
        'At 1,000 rupees a month, that is over 10 years to go.',
      );
      handle.dispose();
    });

    testWidgets('Clear is a 48dp button read as "Clear saving up to"', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));
      await sheet.openTarget(tester);

      final SemanticsNode node = tester.getSemantics(clear);
      expect(node.label, 'Clear saving up to');
      expect(node.flagsCollection.isButton, isTrue);
      expect(tester.getSize(clear).height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });

  group('layout (AC-T12, B1, B2)', () {
    for (final double scale in <double>[1.3, 1.5, 2.0]) {
      testWidgets('at ${scale}x text on 320x568 Clear drops below the amount and nothing overflows', (WidgetTester tester) async {
        await sheet.open(tester, SavingSheet.insurance(rupees: 50000), size: TestWindows.smallPhone, textScale: scale);
        await sheet.openTarget(tester);

        expect(tester.getTopLeft(clear).dy, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AmountDisplay)).dy));
        await tester.ensureVisible(save);
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(TestWindows.smallPhone.height));
        expect(tester.takeException(), isNull);
      });
    }

    // why: at 320x568 from 1.3x the stacked Clear leaves the lead under one line of text, so only
    // these windows can show line 1 with the pinned amount and keypad (see the task report).
    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('320x568', TestWindows.smallPhone, 1),
      ('phone at 2.0x text', TestWindows.phone, 2),
    ]) {
      testWidgets('on $name the lead is anchored to its end: slot line 1 sits on screen above the amount (B1)', (WidgetTester tester) async {
        final PinnedCase window = (name: name, size: size, textScale: scale, bottomInset: 0, features: const <DisplayFeature>[]);
        await sheet.open(tester, SavingSheet.insurance(rupees: 50000), size: size, textScale: scale);
        await sheet.openTarget(tester);

        expectPinnedOnScreen(tester, window: window, amount: find.byType(AmountDisplay), action: save);
        final Rect line = tester.getRect(find.byKey(const ValueKey<String>('target-slot-line-1')));
        expect(line.top, greaterThanOrEqualTo(0));
        expect(line.bottom, lessThanOrEqualTo(tester.getRect(find.byType(AmountDisplay)).top));
        expect(tester.getRect(find.text('How much are you saving up to?')).top, lessThan(0));
      });
    }

    testWidgets('at 1x text Clear sits beside the amount', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));
      await sheet.openTarget(tester);

      expect(tester.getCenter(clear).dy, closeTo(tester.getCenter(find.byType(AmountDisplay)).dy, 40));
      expect(tester.getTopLeft(clear).dx, greaterThan(tester.getTopLeft(find.byType(AmountDisplay)).dx));
    });

    testWidgets('the question meets the tap-target and label guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));
      await sheet.openTarget(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
