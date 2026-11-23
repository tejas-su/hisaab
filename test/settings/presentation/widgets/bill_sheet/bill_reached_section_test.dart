import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:hisaab/settings/presentation/pages/bill_sheet.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/bloc_dispatch.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/saving_sheet.dart';

/// The reached choices on a saving's sheet: *I bought it* and *Keep saving* (SPEC BR-23, FR-SE-1
/// AC-T9 to AC-T11, D213). Insurance has ₹12,000 set aside.
void main() {
  late SavingSheet sheet;

  setUp(() => sheet = SavingSheet());
  tearDown(() => sheet.dispose());

  final Finder bought = find.byKey(const ValueKey<String>('bill-bought'));
  final Finder keep = find.byKey(const ValueKey<String>('bill-keep-saving'));
  final Finder used = find.byKey(const ValueKey<String>('bill-used'));
  final Finder setAside = find.byKey(const ValueKey<String>('bill-set-aside'));

  group('when the keys show (AC-T9)', () {
    for (final int target in <int>[12000, 8000]) {
      testWidgets('a target of ₹$target with ₹12,000 set aside shows both keys above Used some of it', (WidgetTester tester) async {
        await sheet.open(tester, SavingSheet.insurance(rupees: target));

        expect(find.text('I bought it'), findsOneWidget);
        expect(find.text('Keep saving'), findsOneWidget);
        expect(used, findsOneWidget);
        expect(tester.getTopLeft(keep).dy, greaterThan(tester.getTopLeft(bought).dy));
        expect(tester.getTopLeft(used).dy, greaterThan(tester.getTopLeft(keep).dy));
      });
    }

    testWidgets('a target above what is set aside shows neither', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 12001));

      expect(bought, findsNothing);
      expect(keep, findsNothing);
    });

    testWidgets('no target shows neither', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance());

      expect(bought, findsNothing);
    });

    testWidgets('nothing set aside shows neither', (WidgetTester tester) async {
      sheet.ledger.entries.removeWhere((Entry e) => e.recurringId == 5);
      await sheet.open(tester, SavingSheet.insurance(rupees: 12000));

      expect(bought, findsNothing);
    });
  });

  group('a stopped saving (D213, AC-T6)', () {
    testWidgets('the slip says reached and draws neither the put-in stamp nor the next date', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 12000));

      expect(tester.widget<Text>(setAside).data, '₹12,000 set aside · reached ₹12,000');
      expect(find.textContaining('Put in'), findsNothing);
      expect(find.textContaining('Next due on'), findsNothing);
    });

    testWidgets('a saving still putting in keeps its stamp and next date', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 50000));

      expect(find.textContaining('Put in'), findsOneWidget);
      expect(find.textContaining('Next due on'), findsOneWidget);
    });
  });

  group('I bought it (AC-T9, E152)', () {
    testWidgets('closes the sheet with BillSheetBought: the whole amount used, the saving deleted', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await sheet.open(tester, SavingSheet.insurance(rupees: 12000));

      await tester.ensureVisible(bought);
      await tester.tap(bought);
      await tester.settle();

      expect(find.byType(BillSheet), findsNothing);
      final BillSheetOutcome result = await tester.runAsync(() => outcome) ?? fail('no outcome');
      expect(result, isA<BillSheetBought>());
      expect((result as BillSheetBought).outcome.entry.amount, Money.fromMajor(12000));
      expect(sheet.recurring.stopped.single.id, 5);
    });

    testWidgets('a failed write stays on the sheet and says so', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 12000));
      sheet.categories.failure = DatabaseFailure('categories');

      await tester.ensureVisible(bought);
      await tester.tap(bought);
      await tester.settle();

      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(bought, findsOneWidget);
    });
  });

  group('Keep saving (AC-T10, E153)', () {
    testWidgets('clears the target: the keys go, the row reads "Not set" and the foot says "Changed."', (WidgetTester tester) async {
      await sheet.open(tester, SavingSheet.insurance(rupees: 12000));

      await tester.ensureVisible(keep);
      await tester.tap(keep);
      await tester.settle();

      expect(bought, findsNothing);
      expect(keep, findsNothing);
      expect(find.descendant(of: find.byKey(const ValueKey<String>('bill-row-target')), matching: find.text('Not set')), findsOneWidget);
      expect(find.text('Changed.'), findsOneWidget);
      expect(tester.widget<Text>(setAside).data, '₹12,000 set aside');
      expect(sheet.recurring.updates.single.target, const Option<Money>.none());
    });
  });

  group('closing with no choice (AC-T11, E154)', () {
    testWidgets('leaves the saving as it is', (WidgetTester tester) async {
      final Future<BillSheetOutcome> outcome = await sheet.open(tester, SavingSheet.insurance(rupees: 12000));

      await tester.binding.handlePopRoute();
      await tester.settle();

      expect(await tester.runAsync(() => outcome), isA<BillSheetUnchanged>());
      expect(sheet.recurring.updates, isEmpty);
      expect(sheet.ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
    });
  });

  group('large text', () {
    for (final double scale in <double>[1.3, 2.0]) {
      testWidgets('at ${scale}x on 320x568 the keys fit and nothing overflows', (WidgetTester tester) async {
        await sheet.open(tester, SavingSheet.insurance(rupees: 12000), size: TestWindows.smallPhone, textScale: scale);

        await tester.ensureVisible(keep);
        expect(tester.getSize(bought).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
