import 'package:expense_tracker/add_entry/presentation/widgets/spend_preview_line.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('SpendPreviewLine (FR-AD-3)', () {
    testWidgets('on the last day an overspend has no tomorrow part', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SpendPreviewLine(
            preview: Option<SpendPreview>.of(OverTodayShare(over: Money.fromMajor(20), tomorrow: const Option<Money>.none())),
          ),
        ),
      );
      expect(find.text("₹20 over today's share"), findsOneWidget);
    });

    testWidgets('keeps its height with nothing to say', (WidgetTester tester) async {
      await pumpApp(tester, const Scaffold(body: Center(child: SpendPreviewLine(preview: Option<SpendPreview>.none()))));
      expect(tester.getSize(find.byType(SpendPreviewLine)).height, greaterThan(0));
    });
  });
}
