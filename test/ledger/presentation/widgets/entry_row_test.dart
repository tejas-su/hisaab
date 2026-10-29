import 'package:expense_tracker/ledger/ledger.dart';
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
}
