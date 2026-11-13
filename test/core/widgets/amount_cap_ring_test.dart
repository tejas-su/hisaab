import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/widgets/amount_cap_ring.dart';
import 'package:hisaab/core/widgets/amount_display.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AmountCapRing (FR-AD-2, E13)', () {
    final Finder ring = find.byKey(const ValueKey<String>('amount-cap-ring'));
    const String line = "That's the most you can type.";

    Future<void> pump(WidgetTester tester, {required int rejections, required int rupees, bool reduceMotion = false}) => pumpApp(
          tester,
          Scaffold(body: Center(child: AmountDisplay(amount: Money.fromMajor(rupees), rejections: rejections))),
          reduceMotion: reduceMotion,
        );

    testWidgets('shows no ring and says nothing until a key is refused', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, rejections: 0, rupees: 999999999);
      expect(ring, findsNothing);
      expect(find.bySemanticsLabel(line), findsNothing);
      handle.dispose();
    });

    testWidgets('a refused key holds a ring and says why once, politely', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, rejections: 0, rupees: 999999999);
      await pump(tester, rejections: 1, rupees: 999999999);
      expect(ring, findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel(line)).flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('the ring stays through more refused keys and later frames', (WidgetTester tester) async {
      await pump(tester, rejections: 1, rupees: 999999999);
      await pump(tester, rejections: 2, rupees: 999999999);
      await tester.pump(const Duration(seconds: 5));
      expect(ring, findsOneWidget);
    });

    testWidgets('the next accepted key, or a backspace, lowers it', (WidgetTester tester) async {
      await pump(tester, rejections: 0, rupees: 999999999);
      await pump(tester, rejections: 1, rupees: 999999999);
      await pump(tester, rejections: 1, rupees: 99999999);
      expect(ring, findsNothing);
    });

    testWidgets('under reduced motion, where the shake is skipped, the ring still shows', (WidgetTester tester) async {
      await pump(tester, rejections: 0, rupees: 999999999, reduceMotion: true);
      await pump(tester, rejections: 1, rupees: 999999999, reduceMotion: true);
      expect(ring, findsOneWidget);
    });

    testWidgets('the ring takes the amount\'s own colour', (WidgetTester tester) async {
      await pump(tester, rejections: 0, rupees: 999999999);
      await pump(tester, rejections: 1, rupees: 999999999);
      final BoxDecoration decoration = tester.widget<DecoratedBox>(ring).decoration as BoxDecoration;
      final Color amountInk = Theme.of(tester.element(find.byType(AmountCapRing))).textTheme.displayMedium!.color!;
      expect((decoration.border! as Border).top.color, amountInk);
    });
  });
}
