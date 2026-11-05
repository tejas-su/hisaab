import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/design/app_icon.dart';
import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/focus_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('EntryRow typography (D68)', () {
    testWidgets('the category is Regular, the note Regular grey, and the amount Bold', (WidgetTester tester) async {
      final Entry chai = WorkedExample.entries[3];
      await pumpApp(
        tester,
        Scaffold(
          body: EntryRow(
            entry: chai,
            category: seedCategories.first,
            onEdit: () {},
            onDelete: () {},
            onThresholdReached: () {},
          ),
        ),
      );
      final TextStyle? title = tester.widget<Text>(find.text('Food')).style;
      final TextStyle? note = tester.widget<Text>(find.text('Chai & samosa')).style;
      final TextStyle? amount = tester.widget<Text>(find.text('₹60')).style;
      expect(title?.fontWeight, FontWeight.w400);
      expect(title?.fontSize, 16);
      expect(note?.fontWeight, FontWeight.w400);
      expect(amount?.fontWeight, FontWeight.w700);
    });
  });

  group('EntryRow focus (D99)', () {
    testWidgets('keyboard focus draws the ring inside the row, with no Material focus fill', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      await pumpApp(tester, Scaffold(body: EntryRow(
            entry: WorkedExample.entries[3],
            category: seedCategories.first,
            onEdit: () {},
            onDelete: () {},
            onThresholdReached: () {},
          )));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(showsFocusRing(tester, find.byType(EntryRow)), isTrue);
      expect(tester.widget<InkWell>(find.byType(InkWell)).focusColor, HisaabColors.light.clear);
      expect(
        focusRingPaint(find.byType(EntryRow)),
        paints
          ..path()
          ..path(excludes: <Offset>[const Offset(-0.5, 20)]),
      );
    });
  });

  group('EntryRow bill tag (D119)', () {
    Entry bill({String? note, int? recurringId = 3, EntryKind kind = EntryKind.spent}) => Entry(
          id: 50,
          amount: Money.fromMajor(1200),
          kind: kind,
          categoryId: seedCategories.first.id,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          recurringId: recurringId,
          note: note,
        );

    Future<void> pumpRow(WidgetTester tester, Entry entry) => pumpApp(
          tester,
          Scaffold(
            body: EntryRow(entry: entry, category: seedCategories.first, onEdit: () {}, onDelete: () {}, onThresholdReached: () {}),
          ),
        );

    testWidgets('a rule-posted Spent entry with no note shows "Bill" (D123)', (WidgetTester tester) async {
      await pumpRow(tester, bill());
      expect(find.text('Bill'), findsOneWidget);
    });

    testWidgets('a typed entry shows no bill tag', (WidgetTester tester) async {
      await pumpRow(tester, bill(recurringId: null));
      expect(find.text('Bill'), findsNothing);
    });

    testWidgets('a rule-posted entry with a note shows the note, not the tag', (WidgetTester tester) async {
      await pumpRow(tester, bill(note: 'October'));
      expect(find.text('October'), findsOneWidget);
      expect(find.text('Bill'), findsNothing);
    });

    testWidgets('a rule-posted Got entry (salary) shows no bill tag', (WidgetTester tester) async {
      await pumpRow(tester, bill(kind: EntryKind.got, recurringId: 1));
      expect(find.text('Bill'), findsNothing);
    });
  });

  group('EntryRow card bill (D123)', () {
    testWidgets('reads Credit card · Paid, not counted again, with the card glyph; no tap, but swipes away', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> calls = <String>[];
      await pumpApp(
        tester,
        Scaffold(
          body: EntryRow(
            entry: Entry(
              id: 80,
              amount: Money.fromMajor(8000),
              kind: EntryKind.cardPaid,
              categoryId: 12,
              date: WorkedExample.today,
              createdAt: WorkedExample.now,
              recurringId: 9,
              note: 'Credit card',
            ),
            category: null,
            onEdit: () => calls.add('edit'),
            onDelete: () => calls.add('delete'),
            onThresholdReached: () {},
          ),
        ),
      );
      expect(find.text('Credit card'), findsOneWidget);
      expect(find.text('Paid, not counted again'), findsOneWidget);
      expect(find.text('₹8,000'), findsOneWidget);
      expect(tester.widget<AppIcon>(find.byType(AppIcon).last).icon, BillIcon.card.glyph);
      await tester.tap(find.text('Credit card'));
      await tester.pump();
      expect(calls, isEmpty);
      expect(tester.getSemantics(find.text('Credit card')), isSemantics(hasTapAction: false));
      await tester.fling(find.byType(EntryRow), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(calls, <String>['delete']);
      handle.dispose();
    });
  });

  group('EntryRow saved (D120)', () {
    Entry saved({String? note = 'RD', int? recurringId = 4}) => Entry(
          id: 70,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: 11,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          recurringId: recurringId,
          note: note,
        );

    Future<List<String>> pumpRow(WidgetTester tester, Entry entry) async {
      final List<String> calls = <String>[];
      await pumpApp(
        tester,
        Scaffold(
          body: EntryRow(
            entry: entry,
            category: null,
            onEdit: () => calls.add('edit'),
            onDelete: () => calls.add('delete'),
            onThresholdReached: () {},
          ),
        ),
      );
      return calls;
    }

    testWidgets('a posted saving reads RD · Saved · ₹5,000', (WidgetTester tester) async {
      await pumpRow(tester, saved());
      expect(find.text('RD'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
      expect(tester.widget<AppIcon>(find.byType(AppIcon).last).icon, AppIcons.saving);
    });

    testWidgets('an extra reads Put in extra', (WidgetTester tester) async {
      await pumpRow(tester, saved(note: null, recurringId: null));
      expect(find.text('Put in extra'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('a saved row has no tap action but can still be swiped away', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> calls = await pumpRow(tester, saved());
      await tester.tap(find.text('RD'));
      await tester.pump();
      expect(calls, isEmpty);
      expect(tester.getSemantics(find.text('RD')), isSemantics(hasTapAction: false));
      await tester.fling(find.byType(EntryRow), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(calls, <String>['delete']);
      handle.dispose();
    });
  });
}
