import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
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
}
