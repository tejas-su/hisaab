import 'package:expense_tracker/settings/presentation/widgets/bill_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('BillRow typography (D68)', () {
    testWidgets('the bill name is Regular row text and the day a Regular caption', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: BillRow(bill: WorkedExample.rent, onEdit: () {}, onDelete: () {}, onThresholdReached: () {})),
      );
      final TextStyle? name = tester.widget<Text>(find.text('Rent')).style;
      expect(name?.fontWeight, FontWeight.w400);
      expect(name?.fontSize, 16);
      final Text when = tester.widget<Text>(find.textContaining('day 5'));
      expect(when.style?.fontWeight, FontWeight.w400);
    });
  });
}
