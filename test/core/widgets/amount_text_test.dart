import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/widgets/amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Widget _host(ValueNotifier<Money> amount, {bool roll = true}) => Scaffold(
      body: ValueListenableBuilder<Money>(
        valueListenable: amount,
        builder: (BuildContext _, Money value, Widget? __) => AmountText(value, roll: roll),
      ),
    );

void main() {
  group('AmountText', () {
    late ValueNotifier<Money> amount;

    setUp(() => amount = ValueNotifier<Money>(Money.fromMajor(1850)));
    tearDown(() => amount.dispose());

    testWidgets('shows Indian grouping and reads as rupees', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      amount.value = Money.fromMajor(125000);
      await pumpApp(tester, _host(amount));
      expect(find.text('₹1,25,000'), findsOneWidget);
      expect(find.bySemanticsLabel('1,25,000 rupees'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('rolls through values to the new amount', (WidgetTester tester) async {
      await pumpApp(tester, _host(amount));
      amount.value = Money.fromMajor(1430);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('₹1,430'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('₹1,430'), findsOneWidget);
    });

    testWidgets('changes at once while typing', (WidgetTester tester) async {
      await pumpApp(tester, _host(amount, roll: false));
      amount.value = Money.fromMajor(18500);
      await tester.pump();
      expect(find.text('₹18,500'), findsOneWidget);
    });

    testWidgets('crossfades instead of rolling with reduced motion', (WidgetTester tester) async {
      await pumpApp(tester, _host(amount), reduceMotion: true);
      amount.value = Money.fromMajor(1430);
      await tester.pumpAndSettle();
      expect(find.text('₹1,430'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });
}
